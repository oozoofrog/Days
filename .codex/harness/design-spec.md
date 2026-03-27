# Days Design Spec — Word + Reflection

## Design intent
기존 Days의 조용한 톤을 유지하면서, 기록을 단어에서 한 줄 장면으로 확장한다. 새 UI는 “더 많이 쓰게 하는 폼”이 아니라 “다음 한 걸음을 자연스럽게 보여주는 카드”처럼 보여야 한다.

## UX flow
1. 타임라인 진입
2. `이번 사이를 한 단어로 남겨두기` 섹션에서 word 입력
3. 저장 후 `오늘 왜 이 단어야?` 질문이 나타남
4. 사용자는 reflection 저장 또는 `건너뛰기` 선택
5. 카드 하단에서 최근 남긴 기록 프리뷰 확인

## UI structure
- 기존 Hero/Insight/Stat 카드 구조 유지
- 입력 카드는 아래 순서로 배치
  - word input row
  - reflection composer 또는 `이유 더하기` CTA
  - 최근 남긴 기록 프리뷰
  - saved words chips

## Copy
- 섹션 제목: `이번 사이를 한 단어로 남겨두기`
- reflection 질문: `오늘 왜 이 단어야?`
- helper copy: `한 줄이면 충분해요.`
- reopen CTA: `이유 더하기`
- skip CTA: `건너뛰기`
- latest preview title: `최근 남긴 기록`

## Interaction rules
- word 저장 전에는 reflection composer를 숨긴다.
- 현재 방문에 word가 생기면 reflection composer를 연다.
- 사용자가 스킵하면 이번 세션에서는 composer를 접고, `이유 더하기` 버튼으로 다시 열 수 있다.
- 최신 프리뷰는 최근 방문이 비어 있으면 이전에 남긴 가장 최근 기록을 보여준다.

## Visual rules
- 기존 다크 테마와 카드 재질 유지
- 입력 필드, CTA, 프리뷰 간 간격은 현행 card spacing 체계에 맞춘다.
- reflection 입력은 multiline TextField(axis: .vertical)로 가볍게 유지한다.
- 버튼 스타일은 existing bordered/borderedProminent 계열을 재사용한다.

## Accessibility
- 기존 44pt 이상 터치 타깃 유지
- 모든 새 입력/버튼에 accessibility identifier 부여
- Dynamic Type에서 프리뷰 텍스트와 버튼 줄바꿈 허용
