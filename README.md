# 📚 오늘의 도서관 (Today's Library)

**도서관 인포메이션 데스크를 위한 직관적인 방문자 집계 및 통계 프로그램**

![Windows](https://img.shields.io/badge/OS-Windows-blue?logo=windows&logoColor=white)
![Flutter](https://img.shields.io/badge/Built_with-Flutter-02569B?logo=flutter&logoColor=white)
![Release](https://img.shields.io/badge/Release-v1.1.0-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

---


<img src="https://github.com/user-attachments/assets/dfc5884e-bce8-4df5-835a-a927e29e9a03" width="600" alt="스플래시 및 실행 화면">

## 📖 소개 (Overview)
'오늘의 도서관'은 도서관 현장 사서분들의 실무 편의성을 위해 개발된 **데스크톱(Windows) 전용 방문자 카운팅 애플리케이션**입니다.
복잡한 설치 과정이나 무거운 서버 구축 없이, 다운로드 후 즉시 실행 가능한 포터블(Portable) 형태로 제공되며, 실제 데스크 업무 환경(저해상도 모니터, 다중 프로그램 사용)에 최적화되어 있습니다.

## ✨ 주요 기능 (Key Features)

### 1. 🖥️ 멀티태스킹 (콤팩트 모드)
- **초소형 위젯 모드:** 타 업무 프로그램(도서 대출/반납, 엑셀 등)과 화면을 함께 쓸 수 있도록 최소 **350x500px**까지 축소되는 '콤팩트 모드'를 지원합니다.
- **스마트 네비게이션:** 좁은 콤팩트 창 안에서도 **좌우 화살표**를 통해 다른 시간대 기록을 조회/수정할 수 있으며, **'현재 시간대'** 버튼으로 언제든 실시간 운영 시간대로 즉시 스냅(Snap) 복귀할 수 있습니다.

<img src="https://github.com/user-attachments/assets/a0640a70-73a0-4352-965f-c13fe07c2afd" width="400" alt="콤팩트 모드 화면"/>

### 2. 📊 직관적이고 안전한 실시간 방문자 집계
- **대상별 카운팅:** 성인, 아동, 유아를 구분하여 원클릭으로 집계하며, 좌측 패널에서 대상별 수치와 **당일 전체 누적 합계**를 한눈에 확인할 수 있습니다.
- **오조작(휴먼 에러) 원천 차단:** 모든 개별/전체 초기화(휴지통) 버튼 클릭 시 **재확인(경고) 팝업**을 띄우고, 마우스 호버(Hover) 시 붉은색 반전 효과를 주어 소중한 데이터 유실을 방지합니다.

<img src="https://github.com/user-attachments/assets/99598d07-794c-4c5c-9960-0017052e0868" width="600" alt="메인 집계 화면"/>

### 3. 🕒 유연한 맞춤형 스케줄링
- **맞춤형 운영 시간:** 도서관의 실제 운영 시간(최대 00:00 ~ 24:00)과 휴관일을 요일별로 자유롭게 커스텀할 수 있습니다.
- **스마트 자동 이동:** 설정한 운영 시간에 맞춰 1시간 단위로 슬롯이 자동 생성되며, 실제 시간에 따라 **현재 시간대가 자동으로 선택**됩니다.

<img src="https://github.com/user-attachments/assets/b0b75d98-7f63-49fa-8094-dca8db51d766" width="500" alt="요일별 운영시간 설정 창">

### 4. 📈시각화 및 통계
* **다양한 기준의 통계:** 일별, 월별, 연도별, 전체 누적 통계를 지원합니다.
* **동적 차트 제공:** 데이터의 성격에 따라 누적 막대 그래프와 꺾은선 그래프(개별 트렌드)를 스위칭하여 분석할 수 있습니다.
* **인터랙티브 툴팁:** 차트 마우스 오버 시 대상별 세부 수치를 명확하게 제공합니다.


<img src="https://github.com/user-attachments/assets/a5282568-0474-40c7-b50b-a2c5fd08a02a" width="400" alt="통계 막대 차트 화면"/>
<img src="https://github.com/user-attachments/assets/fc2bf07c-4f90-41d8-858d-6719c5b317d4" width="400" alt="통계 꺾은선 차트 화면"/>

### 5. 📑 엑셀 리포트 자동 생성
* 버튼 한 번으로 바탕화면에 **`.xlsx` 통계 보고서가 다운로드**됩니다.(교차 배경색, 맑은 고딕, 헤더 강조, 셀 너비 자동 맞춤 등 서식 자동 적용)
* 마스터 요약(연도별), 월별, 일별, 시간대별 상세 원본 시트가 자동 분리되어 즉시 보고용으로 사용할 수 있습니다.

<img src="https://github.com/user-attachments/assets/54b84ff0-504e-468a-be74-d754b57b4b43" width="600" alt="엑셀 출력 결과물">

### 6. 💻 데스크톱 환경 최적화
* **독립적 창 크기 영구 기억:** 앱을 재실행해도 위치가 유지되며, 특히 '일반 모드'와 '콤팩트 모드' 각각의 창 크기를 독립적으로 기억하여(`shared_preferences` 활용) 완벽한 개인화 환경을 제공합니다.
* **항상 위 고정 핀셋 기능:** 다른 업무 창을 띄워놓고 작업하더라도 카운터 창을 항상 화면 최상단에 고정할 수 있습니다.
* **공장 초기화(Factory Reset) 지원:** 포터블 앱 삭제 전, 윈도우 PC 내부에 남은 방문자 DB와 설정값을 영구적으로 지울 수 있는 안전한 초기화 기능을 설정 창(위험 구역)에서 제공합니다.

---

## 🛠 기술 스택 (Tech Stack)
* **Framework:** Flutter (Dart)
* **Database & Storage:** SQLite (`sqflite_common_ffi`), `shared_preferences`
* **Charts:** `fl_chart`
* **Excel Export:** `excel`
* **Desktop Control:** `window_manager` (창 제어), `package_info_plus` (버전 관리)

---

## 🚀 다운로드 및 실행 방법 (How to use)
이 프로그램은 설치가 필요 없는 단일 실행 환경을 제공합니다.

1. 우측의 **[Releases]** 탭 또는 **[Actions]** 탭에서 가장 최신 빌드의 `Todays_Library_Windows.zip` 파일을 다운로드합니다.
2. 압축을 해제합니다.
3. 폴더 내의 **`todays_library.exe`** 파일을 더블클릭하여 실행합니다.
> 💡 **Tip:** `todays_library.exe` 파일을 마우스 우클릭한 후 **[보내기] > [바탕 화면에 바로 가기 만들기]** 를 선택하시면, 앞으로 바탕화면에서 더욱 편리하게 앱을 실행하실 수 있습니다. (Windows 11의 경우 우클릭 후 '더 많은 옵션 표시' 클릭)
>
> 바탕화면에 생성된 바로 가기 아이콘의 이름은 **'오늘의 도서관'** 등 원하시는 이름으로 자유롭게 변경(`F2` 키 또는 우클릭 후 이름 바꾸기)하여 사용하셔도 프로그램 실행에 전혀 지장이 없습니다.

### ⚠️ 실행 시 주의사항 (Windows SmartScreen 알림)
본 프로그램은 무료로 배포되는 오픈소스 앱이므로, 다운로드 후 처음 실행할 때 **'Windows의 PC 보호 (Microsoft Defender SmartScreen)'** 파란색 알림창이 나타날 수 있습니다.
이는 유료 인증서가 없는 1인 개발/오픈소스 프로그램에서 공통적으로 발생하는 윈도우의 기본 보안 안내일 뿐, **바이러스나 악성코드가 아니니 안심하셔도 됩니다.**

**[해결 방법]**
1. 파란색 팝업창 본문에서 **`추가 정보`** 글자를 클릭합니다.
2. 우측 하단에 나타나는 **`실행`** 버튼을 누르시면 정상적으로 프로그램이 작동합니다. (최초 1회만 수행)

---

## 📜 라이선스 (License)
이 프로젝트는 **MIT License**를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 확인해 주세요.

앱 내부에서 사용된 오픈소스 패키지 및 폰트(Pretendard)에 대한 세부 라이선스 정보는 [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md) 문서 또는 앱 내의 **[정보(i) 아이콘 > 라이선스 보기]** 에서 직접 확인하실 수 있습니다.

---
*Copyright (c) 2026 Lirpa*