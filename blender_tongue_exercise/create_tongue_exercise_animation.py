"""
Create an educational tongue exercise animation in Blender 4.x.

This script intentionally uses simple procedural geometry. It is not a
medically accurate anatomy model; it is a clean visualization scaffold that can
later be adapted to a real scanned/modelled tongue asset.

Run:
    blender --background --python create_tongue_exercise_animation.py
"""

from __future__ import annotations

import math
import os
from dataclasses import dataclass
from typing import Iterable

import bpy
from mathutils import Vector


FPS = 24
EXERCISE_SECONDS = 3
RETURN_SECONDS = 1
EXERCISE_FRAMES = FPS * EXERCISE_SECONDS
RETURN_FRAMES = FPS * RETURN_SECONDS

OUTPUT_BASENAME = "tongue_exercise_animation"


@dataclass(frozen=True)
class ControlPoint:
    """A procedural tongue cross-section control point.

    x, y, z define the center of the cross-section.
    width controls left/right radius.
    thickness controls up/down radius.
    """

    x: float
    y: float
    z: float
    width: float
    thickness: float


@dataclass(frozen=True)
class ExerciseSegment:
    name: str
    marker_name: str
    shape_sequence: tuple[str, ...]
    arrow_name: str | None = None


def clear_scene() -> None:
    """Remove all existing scene objects and reset animation data."""

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    bpy.context.scene.timeline_markers.clear()


def configure_scene() -> None:
    """Set timeline, units, render settings, and color management."""

    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_set(1)
    scene.render.fps = FPS
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.eevee.taa_render_samples = 64
    scene.view_settings.view_transform = "Filmic"
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.exposure = 0.0
    scene.view_settings.gamma = 1.0


def make_material(
    name: str,
    color: tuple[float, float, float, float],
    *,
    roughness: float = 0.55,
    metallic: float = 0.0,
    alpha: float | None = None,
) -> bpy.types.Material:
    """Create a Blender 4 material using Principled BSDF."""

    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Alpha"].default_value = color[3] if alpha is None else alpha

    if color[3] < 1.0 or (alpha is not None and alpha < 1.0):
        material.blend_method = "BLEND"
        if hasattr(material, "use_screen_refraction"):
            material.use_screen_refraction = True
        material.show_transparent_back = True

    return material


def create_materials() -> dict[str, bpy.types.Material]:
    """Central material palette for easy replacement."""

    return {
        "face": make_material("transparent_face_mouth_section", (0.85, 0.62, 0.52, 0.22)),
        "palate": make_material("soft_palate_light_skin", (1.0, 0.68, 0.55, 1.0)),
        "tongue": make_material("tongue_pink", (1.0, 0.28, 0.44, 1.0), roughness=0.75),
        "teeth": make_material("teeth_white", (0.98, 0.96, 0.88, 1.0), roughness=0.35),
        "gum": make_material("gum_soft_pink", (0.95, 0.45, 0.50, 1.0)),
        "arrow_forward": make_material("arrow_forward_blue", (0.12, 0.55, 1.0, 1.0)),
        "arrow_backward": make_material("arrow_backward_cyan", (0.0, 0.85, 0.95, 1.0)),
        "arrow_up": make_material("arrow_up_yellow", (1.0, 0.82, 0.12, 1.0)),
        "arrow_down": make_material("arrow_down_green", (0.25, 0.9, 0.25, 1.0)),
        "arrow_left": make_material("arrow_left_orange", (1.0, 0.45, 0.10, 1.0)),
        "arrow_right": make_material("arrow_right_purple", (0.72, 0.38, 1.0, 1.0)),
        "arrow_circle": make_material("arrow_circle_magenta", (1.0, 0.16, 0.78, 1.0)),
        "text": make_material("label_text_white", (1.0, 1.0, 1.0, 1.0)),
    }


def shade_smooth(obj: bpy.types.Object) -> None:
    """Apply smooth shading to mesh polygons."""

    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.shade_smooth()
    obj.select_set(False)


def add_bevel_modifier(obj: bpy.types.Object, amount: float, segments: int = 4) -> None:
    """Round simple mesh edges without applying the modifier."""

    bevel = obj.modifiers.new(name="soft_rounding", type="BEVEL")
    bevel.width = amount
    bevel.segments = segments
    bevel.affect = "EDGES"
    obj.modifiers.new(name="weighted_normals", type="WEIGHTED_NORMAL")


def create_face_cutaway(materials: dict[str, bpy.types.Material]) -> bpy.types.Object:
    """Create a translucent simplified head/cheek cutaway shell."""

    bpy.ops.mesh.primitive_uv_sphere_add(segments=64, ring_count=32, location=(0.15, 0.05, 0.28))
    face = bpy.context.object
    face.name = "transparent_face_and_mouth_cutaway"
    face.scale = (1.45, 1.15, 1.65)
    face.data.materials.append(materials["face"])
    shade_smooth(face)

    # A translucent face shell can visually crowd the mouth. Keep it wire-visible
    # in the viewport/render by adding a solidify-like thin outline feel.
    face.display_type = "TEXTURED"
    return face


def create_palate(materials: dict[str, bpy.types.Material]) -> bpy.types.Object:
    """Create a simple arched palate/roof of mouth mesh."""

    vertices: list[tuple[float, float, float]] = []
    faces: list[tuple[int, int, int, int]] = []
    y_values = [-1.05 + i * 0.23 for i in range(10)]
    x_values = [-0.58 + i * 0.145 for i in range(9)]

    for y in y_values:
        for x in x_values:
            arch = 0.26 * (1.0 - min(abs(x) / 0.65, 1.0) ** 2)
            vertices.append((x, y, 0.45 + arch))

    width_count = len(x_values)
    for yi in range(len(y_values) - 1):
        for xi in range(len(x_values) - 1):
            a = yi * width_count + xi
            faces.append((a, a + 1, a + width_count + 1, a + width_count))

    mesh = bpy.data.meshes.new("palate_mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    palate = bpy.data.objects.new("arched_palate", mesh)
    bpy.context.collection.objects.link(palate)
    palate.data.materials.append(materials["palate"])
    shade_smooth(palate)
    palate.modifiers.new(name="palate_smooth", type="WEIGHTED_NORMAL")
    return palate


def create_teeth(materials: dict[str, bpy.types.Material]) -> list[bpy.types.Object]:
    """Create stylized upper/lower teeth as rounded small blocks."""

    teeth: list[bpy.types.Object] = []
    x_positions = [-0.42, -0.25, -0.08, 0.08, 0.25, 0.42]

    for row_name, z, y, height in (
        ("upper_teeth", 0.32, -0.78, 0.20),
        ("lower_teeth", -0.28, -0.78, 0.16),
    ):
        for idx, x in enumerate(x_positions):
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, y, z))
            tooth = bpy.context.object
            tooth.name = f"{row_name}_{idx + 1:02d}"
            tooth.dimensions = (0.13, 0.12, height)
            bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
            tooth.data.materials.append(materials["teeth"])
            add_bevel_modifier(tooth, 0.035, segments=5)
            teeth.append(tooth)

    return teeth


def create_gums(materials: dict[str, bpy.types.Material]) -> list[bpy.types.Object]:
    """Add small gum bars to frame the teeth."""

    gums: list[bpy.types.Object] = []
    for name, z in (("upper_gum", 0.44), ("lower_gum", -0.42)):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, -0.80, z))
        gum = bpy.context.object
        gum.name = name
        gum.dimensions = (1.1, 0.10, 0.08)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        gum.data.materials.append(materials["gum"])
        add_bevel_modifier(gum, 0.04, segments=5)
        gums.append(gum)
    return gums


def neutral_tongue_control_points() -> list[ControlPoint]:
    """Base control point curve for the procedural tongue model."""

    # Back of tongue is positive Y; tip is negative Y.
    return [
        ControlPoint(0.0, 0.55, -0.16, 0.46, 0.14),
        ControlPoint(0.0, 0.32, -0.13, 0.49, 0.15),
        ControlPoint(0.0, 0.08, -0.10, 0.50, 0.15),
        ControlPoint(0.0, -0.16, -0.08, 0.47, 0.14),
        ControlPoint(0.0, -0.40, -0.06, 0.40, 0.12),
        ControlPoint(0.0, -0.62, -0.04, 0.31, 0.10),
        ControlPoint(0.0, -0.82, -0.02, 0.22, 0.08),
        ControlPoint(0.0, -0.98, 0.00, 0.13, 0.055),
    ]


def deform_control_points(
    base: Iterable[ControlPoint],
    *,
    tip_x: float = 0.0,
    tip_y: float = 0.0,
    tip_z: float = 0.0,
    whole_x: float = 0.0,
    whole_y: float = 0.0,
    whole_z: float = 0.0,
    width_scale: float = 1.0,
) -> list[ControlPoint]:
    """Create a smooth pose by weighting offsets toward the tongue tip."""

    points = list(base)
    max_index = max(len(points) - 1, 1)
    deformed: list[ControlPoint] = []
    for index, point in enumerate(points):
        t = index / max_index
        tip_weight = t**1.7
        deformed.append(
            ControlPoint(
                point.x + whole_x + tip_x * tip_weight,
                point.y + whole_y + tip_y * tip_weight,
                point.z + whole_z + tip_z * tip_weight,
                point.width * (1.0 + (width_scale - 1.0) * tip_weight),
                point.thickness,
            )
        )
    return deformed


def tongue_vertices_from_control_points(
    control_points: list[ControlPoint],
    radial_segments: int = 16,
) -> list[Vector]:
    """Generate elliptical rings around the control points."""

    vertices: list[Vector] = []
    for cp in control_points:
        for r in range(radial_segments):
            angle = (math.tau * r) / radial_segments
            vertices.append(
                Vector(
                    (
                        cp.x + math.cos(angle) * cp.width,
                        cp.y,
                        cp.z + math.sin(angle) * cp.thickness,
                    )
                )
            )
    return vertices


def tongue_faces(point_count: int, radial_segments: int = 16) -> list[tuple[int, int, int, int]]:
    """Connect tongue cross-section rings into a mesh surface."""

    faces: list[tuple[int, int, int, int]] = []
    for p in range(point_count - 1):
        ring = p * radial_segments
        next_ring = (p + 1) * radial_segments
        for r in range(radial_segments):
            faces.append(
                (
                    ring + r,
                    ring + (r + 1) % radial_segments,
                    next_ring + (r + 1) % radial_segments,
                    next_ring + r,
                )
            )

    # Cap the back and tip rings.
    faces.append(tuple(reversed(range(radial_segments))))
    last_start = (point_count - 1) * radial_segments
    faces.append(tuple(last_start + r for r in range(radial_segments)))
    return faces


def create_tongue(materials: dict[str, bpy.types.Material]) -> bpy.types.Object:
    """Create tongue mesh and shape keys for all requested movements."""

    base_points = neutral_tongue_control_points()
    radial_segments = 16
    mesh = bpy.data.meshes.new("control_point_tongue_mesh")
    base_vertices = tongue_vertices_from_control_points(base_points, radial_segments)
    mesh.from_pydata([tuple(v) for v in base_vertices], [], tongue_faces(len(base_points), radial_segments))
    mesh.update()

    tongue = bpy.data.objects.new("shape_key_control_point_tongue", mesh)
    bpy.context.collection.objects.link(tongue)
    tongue.data.materials.append(materials["tongue"])
    shade_smooth(tongue)
    tongue.modifiers.new(name="tongue_weighted_normals", type="WEIGHTED_NORMAL")

    tongue.shape_key_add(name="Basis")
    pose_points = {
        "protrude": deform_control_points(base_points, tip_y=-0.52, tip_z=0.03, width_scale=0.82),
        "retract": deform_control_points(base_points, tip_y=0.42, tip_z=-0.03, width_scale=1.05),
        "up": deform_control_points(base_points, tip_z=0.48, tip_y=-0.05),
        "down": deform_control_points(base_points, tip_z=-0.35, tip_y=-0.02),
        "left": deform_control_points(base_points, tip_x=-0.46),
        "right": deform_control_points(base_points, tip_x=0.46),
        "circle_up": deform_control_points(base_points, tip_z=0.42, tip_y=-0.08),
        "circle_right": deform_control_points(base_points, tip_x=0.42, tip_y=-0.05),
        "circle_down": deform_control_points(base_points, tip_z=-0.28, tip_y=-0.06),
        "circle_left": deform_control_points(base_points, tip_x=-0.42, tip_y=-0.05),
    }

    for key_name, points in pose_points.items():
        shape_key = tongue.shape_key_add(name=key_name)
        vertices = tongue_vertices_from_control_points(points, radial_segments)
        for index, vertex in enumerate(vertices):
            shape_key.data[index].co = vertex

    return tongue


def create_arrow(
    name: str,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
    material: bpy.types.Material,
    *,
    radius: float = 0.025,
    cone_radius: float = 0.085,
    cone_depth: float = 0.20,
) -> bpy.types.Object:
    """Create an arrow from a bevelled curve shaft and cone head."""

    start_v = Vector(start)
    end_v = Vector(end)
    direction = end_v - start_v

    curve = bpy.data.curves.new(f"{name}_shaft_curve", type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 2
    curve.bevel_depth = radius
    curve.bevel_resolution = 5
    spline = curve.splines.new("POLY")
    spline.points.add(1)
    spline.points[0].co = (start_v.x, start_v.y, start_v.z, 1.0)
    spline.points[1].co = (end_v.x, end_v.y, end_v.z, 1.0)

    shaft = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(shaft)
    shaft.data.materials.append(material)

    bpy.ops.mesh.primitive_cone_add(
        vertices=32,
        radius1=cone_radius,
        radius2=0.0,
        depth=cone_depth,
        location=end_v,
        rotation=direction.to_track_quat("Z", "Y").to_euler(),
    )
    head = bpy.context.object
    head.name = f"{name}_head"
    head.data.materials.append(material)
    shade_smooth(head)
    head.parent = shaft
    return shaft


def create_circular_arrow(name: str, material: bpy.types.Material) -> bpy.types.Object:
    """Create a circular motion arrow near the tongue tip."""

    center = Vector((0.0, -1.08, 0.05))
    radius = 0.35
    curve = bpy.data.curves.new(f"{name}_curve", type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 12
    curve.bevel_depth = 0.022
    curve.bevel_resolution = 5
    spline = curve.splines.new("POLY")
    point_count = 48
    spline.points.add(point_count - 1)
    for index in range(point_count):
        angle = (math.tau * 0.88 * index) / (point_count - 1)
        x = center.x + math.cos(angle) * radius
        z = center.z + math.sin(angle) * radius
        spline.points[index].co = (x, center.y, z, 1.0)

    arrow = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(arrow)
    arrow.data.materials.append(material)

    # Add a cone head tangential to the circular path.
    head_angle = math.tau * 0.88
    head_loc = Vector(
        (
            center.x + math.cos(head_angle) * radius,
            center.y,
            center.z + math.sin(head_angle) * radius,
        )
    )
    tangent = Vector((-math.sin(head_angle), 0.0, math.cos(head_angle)))
    bpy.ops.mesh.primitive_cone_add(
        vertices=32,
        radius1=0.08,
        depth=0.18,
        location=head_loc,
        rotation=tangent.to_track_quat("Z", "Y").to_euler(),
    )
    head = bpy.context.object
    head.name = f"{name}_head"
    head.data.materials.append(material)
    shade_smooth(head)
    head.parent = arrow
    return arrow


def create_arrows(materials: dict[str, bpy.types.Material]) -> dict[str, bpy.types.Object]:
    """Create all exercise direction arrows."""

    arrows = {
        "protrude": create_arrow(
            "arrow_tongue_forward",
            (0.0, -0.70, 0.08),
            (0.0, -1.45, 0.10),
            materials["arrow_forward"],
        ),
        "retract": create_arrow(
            "arrow_tongue_retract",
            (0.0, -1.25, 0.12),
            (0.0, -0.54, 0.08),
            materials["arrow_backward"],
        ),
        "up": create_arrow(
            "arrow_tongue_up",
            (0.0, -1.05, 0.02),
            (0.0, -1.05, 0.68),
            materials["arrow_up"],
        ),
        "down": create_arrow(
            "arrow_tongue_down",
            (0.0, -1.05, 0.16),
            (0.0, -1.05, -0.46),
            materials["arrow_down"],
        ),
        "left": create_arrow(
            "arrow_tongue_left",
            (0.0, -1.05, 0.08),
            (-0.62, -1.05, 0.08),
            materials["arrow_left"],
        ),
        "right": create_arrow(
            "arrow_tongue_right",
            (0.0, -1.05, 0.08),
            (0.62, -1.05, 0.08),
            materials["arrow_right"],
        ),
        "circle": create_circular_arrow("arrow_tongue_circle", materials["arrow_circle"]),
    }
    return arrows


def set_object_visibility(obj: bpy.types.Object, frame: int, visible: bool) -> None:
    """Keyframe object visibility for viewport and render."""

    obj.hide_viewport = not visible
    obj.hide_render = not visible
    obj.keyframe_insert(data_path="hide_viewport", frame=frame)
    obj.keyframe_insert(data_path="hide_render", frame=frame)
    for child in obj.children:
        set_object_visibility(child, frame, visible)


def animate_arrow_visibility(
    arrows: dict[str, bpy.types.Object],
    arrow_name: str | None,
    start_frame: int,
    end_frame: int,
) -> None:
    """Show only the relevant exercise arrow during that exercise segment."""

    if arrow_name is None:
        return
    arrow = arrows[arrow_name]
    set_object_visibility(arrow, max(1, start_frame - 1), False)
    set_object_visibility(arrow, start_frame, True)
    set_object_visibility(arrow, end_frame, True)
    set_object_visibility(arrow, end_frame + 1, False)


def create_camera_and_lights() -> bpy.types.Object:
    """Create a 3/4 cutaway camera and clean teaching-style lighting."""

    bpy.ops.object.light_add(type="AREA", location=(0.0, -3.0, 4.0))
    key_light = bpy.context.object
    key_light.name = "large_softbox_key_light"
    key_light.data.energy = 650
    key_light.data.size = 5.0

    bpy.ops.object.light_add(type="POINT", location=(-2.8, 1.2, 1.8))
    fill_light = bpy.context.object
    fill_light.name = "small_fill_light"
    fill_light.data.energy = 80

    bpy.ops.object.camera_add(location=(3.1, -4.7, 2.2), rotation=(math.radians(65), 0, math.radians(35)))
    camera = bpy.context.object
    camera.name = "camera_3_4_mouth_cutaway"
    look_at(camera, Vector((0.0, -0.35, 0.02)))
    camera.data.lens = 45
    camera.data.dof.use_dof = True
    camera.data.dof.focus_distance = 5.2
    camera.data.dof.aperture_fstop = 7.0
    bpy.context.scene.camera = camera
    return camera


def look_at(obj: bpy.types.Object, target: Vector) -> None:
    """Rotate an object to look at target using Blender camera convention."""

    direction = target - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def create_camera_label(
    camera: bpy.types.Object,
    name: str,
    text: str,
    material: bpy.types.Material,
    *,
    y_offset: float = -0.72,
) -> bpy.types.Object:
    """Create a camera-parented 3D text label."""

    bpy.ops.object.text_add(location=(0.0, 0.0, 0.0), rotation=(0.0, 0.0, 0.0))
    label = bpy.context.object
    label.name = name
    label.data.body = text
    label.data.align_x = "CENTER"
    label.data.align_y = "CENTER"
    label.data.size = 0.105
    label.data.materials.append(material)
    label.parent = camera
    label.location = (0.0, y_offset, -2.15)
    label.rotation_euler = (0.0, 0.0, 0.0)
    return label


def create_exercise_labels(
    camera: bpy.types.Object,
    segments: list[ExerciseSegment],
    materials: dict[str, bpy.types.Material],
) -> dict[str, bpy.types.Object]:
    """Create one camera-facing label per exercise for reliable visibility keys."""

    labels: dict[str, bpy.types.Object] = {}
    for segment in segments:
        labels[segment.name] = create_camera_label(
            camera,
            f"current_exercise_label_{segment.marker_name}",
            segment.name,
            materials["text"],
        )
    return labels


def set_shape_key_value(
    tongue: bpy.types.Object,
    key_name: str,
    frame: int,
    value: float,
) -> None:
    """Set and keyframe a tongue shape key value."""

    key = tongue.data.shape_keys.key_blocks[key_name]
    key.value = value
    key.keyframe_insert(data_path="value", frame=frame)


def reset_all_pose_keys(tongue: bpy.types.Object, frame: int) -> None:
    """Set all non-basis shape keys to zero at a frame."""

    for key in tongue.data.shape_keys.key_blocks:
        if key.name != "Basis":
            key.value = 0.0
            key.keyframe_insert(data_path="value", frame=frame)


def animate_single_pose(tongue: bpy.types.Object, key_name: str, start: int, end: int) -> None:
    """Animate one exercise as ramp in, hold, and return."""

    ramp = FPS
    reset_all_pose_keys(tongue, start)
    set_shape_key_value(tongue, key_name, start, 0.0)
    set_shape_key_value(tongue, key_name, start + ramp, 1.0)
    set_shape_key_value(tongue, key_name, end - ramp, 1.0)
    set_shape_key_value(tongue, key_name, end, 0.0)


def animate_circle_pose(tongue: bpy.types.Object, start: int, end: int) -> None:
    """Animate circular tongue motion using four directional shape keys."""

    reset_all_pose_keys(tongue, start)
    circle_keys = ("circle_up", "circle_right", "circle_down", "circle_left", "circle_up")
    step = max(1, (end - start) // (len(circle_keys) - 1))

    for key_name in ("circle_up", "circle_right", "circle_down", "circle_left"):
        set_shape_key_value(tongue, key_name, start, 0.0)

    for index, active_key in enumerate(circle_keys):
        frame = min(end, start + step * index)
        for key_name in ("circle_up", "circle_right", "circle_down", "circle_left"):
            set_shape_key_value(tongue, key_name, frame, 1.0 if key_name == active_key else 0.0)

    reset_all_pose_keys(tongue, end)


def animate_label_visibility(
    labels: dict[str, bpy.types.Object],
    active_name: str,
    start_frame: int,
    end_frame: int,
) -> None:
    """Show the current exercise label in front of the camera."""

    label = labels[active_name]
    set_object_visibility(label, max(1, start_frame - 1), False)
    set_object_visibility(label, start_frame, True)
    set_object_visibility(label, end_frame, True)
    set_object_visibility(label, end_frame + 1, False)


def add_scene_marker(frame: int, name: str, camera: bpy.types.Object) -> None:
    """Add a timeline marker and bind it to the camera."""

    marker = bpy.context.scene.timeline_markers.new(name=name, frame=frame)
    marker.camera = camera


def exercise_segments() -> list[ExerciseSegment]:
    """All requested tongue exercises in playback order."""

    return [
        ExerciseSegment("중립 자세", "neutral", ()),
        ExerciseSegment("혀 앞으로 내밀기", "protrude", ("protrude",), "protrude"),
        ExerciseSegment("혀 안으로 넣기", "retract", ("retract",), "retract"),
        ExerciseSegment("혀 위로 올리기", "up", ("up",), "up"),
        ExerciseSegment("혀 아래로 내리기", "down", ("down",), "down"),
        ExerciseSegment("혀 왼쪽 이동", "left", ("left",), "left"),
        ExerciseSegment("혀 오른쪽 이동", "right", ("right",), "right"),
        ExerciseSegment(
            "혀 원형 돌리기",
            "circle",
            ("circle_up", "circle_right", "circle_down", "circle_left"),
            "circle",
        ),
    ]


def animate_timeline(
    tongue: bpy.types.Object,
    arrows: dict[str, bpy.types.Object],
    labels: dict[str, bpy.types.Object],
    camera: bpy.types.Object,
    segments: list[ExerciseSegment],
) -> None:
    """Create all timeline markers, shape-key animation, labels, and arrow keys."""

    # Hide labels and arrows at frame 1 before selectively showing them.
    for label in labels.values():
        set_object_visibility(label, 1, False)
    for arrow in arrows.values():
        set_object_visibility(arrow, 1, False)

    frame = 1
    reset_all_pose_keys(tongue, frame)

    for index, segment in enumerate(segments):
        start = frame
        end = start + EXERCISE_FRAMES
        add_scene_marker(start, segment.name, camera)
        animate_label_visibility(labels, segment.name, start, end)
        animate_arrow_visibility(arrows, segment.arrow_name, start, end)

        if not segment.shape_sequence:
            reset_all_pose_keys(tongue, start)
            reset_all_pose_keys(tongue, end)
        elif segment.marker_name == "circle":
            animate_circle_pose(tongue, start, end)
        else:
            animate_single_pose(tongue, segment.shape_sequence[0], start, end)

        # Add 1 second neutral return/hold between exercise segments.
        return_start = end + 1
        return_end = end + RETURN_FRAMES
        reset_all_pose_keys(tongue, return_start)
        reset_all_pose_keys(tongue, return_end)
        frame = return_end + 1

    bpy.context.scene.frame_end = frame - 1


def save_outputs() -> tuple[str, str]:
    """Save the Blender file and export GLB next to this script."""

    script_dir = os.path.dirname(os.path.abspath(__file__))
    blend_path = os.path.join(script_dir, f"{OUTPUT_BASENAME}.blend")
    glb_path = os.path.join(script_dir, f"{OUTPUT_BASENAME}.glb")

    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format="GLB",
        export_animations=True,
        export_apply=False,
    )
    return blend_path, glb_path


def build_scene() -> tuple[str, str]:
    """Build the full educational tongue exercise animation scene."""

    clear_scene()
    configure_scene()
    materials = create_materials()

    create_face_cutaway(materials)
    create_palate(materials)
    create_teeth(materials)
    create_gums(materials)

    tongue = create_tongue(materials)
    arrows = create_arrows(materials)
    camera = create_camera_and_lights()
    segments = exercise_segments()
    labels = create_exercise_labels(camera, segments, materials)
    animate_timeline(tongue, arrows, labels, camera, segments)

    return save_outputs()


if __name__ == "__main__":
    blend_file, glb_file = build_scene()
    print(f"Saved Blender file: {blend_file}")
    print(f"Exported GLB file: {glb_file}")
