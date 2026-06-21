import { OralAlternatingExercise3D } from "./components/OralAlternatingExercise3D";

export default function App() {
  return (
    <main className="app">
      <header className="app-header">
        <span>일반 운동 가이드</span>
        <h1>연속 교대 구강운동 3D 훈련</h1>
      </header>
      <OralAlternatingExercise3D
        autoPlay={false}
        loop
        defaultSpeed={1}
        onStepChange={(index, id) => {
          console.debug("step", index, id);
        }}
      />
      <p className="disclaimer">
        이 콘텐츠는 일반적인 구강운동 안내용이며 의학적 진단이나 치료가 아닙니다.
        증상이 있거나 재활 목적이라면 의사 또는 언어재활사와 상담하세요.
      </p>
    </main>
  );
}
