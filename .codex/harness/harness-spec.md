# Days Harness Spec — Word + Reflection

## Context
Days는 재방문 사이에 흐른 시간을 보여주고, 사용자는 그 시간의 흔적으로 한 단어를 남길 수 있다. 현재는 단어만 저장되기 때문에 기록의 맥락이 약하고, 사용자가 다음 행동을 떠올리기 어렵다.

## Problem
- 기록이 단어에서 멈춘다.
- 회고 시 왜 그 단어를 남겼는지 복원하기 어렵다.
- 입력 후 자연스러운 다음 행동이 부족하다.

## Goal
단어 입력 뒤에 `오늘 왜 이 단어야?` 후속 질문을 제공해, 사용자가 선택적으로 한 줄 이유를 남길 수 있게 한다.

## MVP scope
1. 현재 방문 기록에 word + reflection를 저장할 수 있다.
2. 타임라인 카드에서 word 저장 후 reflection 입력 UI가 열린다.
3. reflection 입력은 선택이며, 스킵 후에도 word-only 기록이 자연스럽게 남는다.
4. 타임라인에서 최근 남긴 기록(word + reflection)을 프리뷰로 볼 수 있다.
5. 단위 테스트/UI 테스트/런치 시나리오를 업데이트한다.

## Non-goals
- 별도 히스토리 상세 화면 추가
- 감정 태그/통계 확장
- AI 요약
- 질문 다양화

## Technical approach
- 영속 모델 `VisitEntry.note`는 유지하고, 새 필드 `reflection`을 추가한다.
- 도메인/프레젠테이션 층에서는 `word` 용어를 사용한다.
- ViewModel에 `wordDraft`, `reflectionDraft`, reflection composer 상태를 추가한다.
- 타임라인 카드에 word 입력, reflection 입력, 스킵/재진입 CTA, 최신 기록 프리뷰를 추가한다.

## Validation
- 단위 테스트: 저장, background autosave, 프레젠테이션 구성
- UI 테스트: 타임라인 진입, word 저장, reflection 저장/스킵
- 시뮬레이터 빌드 및 테스트 실행
