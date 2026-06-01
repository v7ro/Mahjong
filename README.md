# Mahjong Solitaire

Flutter-приложение для Android и iOS.

## Стек

- Flutter 3.x / Dart 3.x
- Firebase Auth — email, Google, Apple
- Cloud Firestore — рейтинг, история
- Firebase Cloud Messaging — пуш-уведомления
- shared_preferences — настройки

## Запуск

```bash
flutter pub get
flutter run
```

Требует `google-services.json` в `android/app/`  
и `GoogleService-Info.plist` в `ios/Runner/`.

## Пуш-уведомления

Настраиваются в Firebase Console → Cloud Messaging.  
Создай кампанию → выбери аудиторию → расписание.  
Например: "Заходи в игру, мы тебя ждём!" раз в неделю.

## Правила Firestore

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
      match /history/{h} {
        allow read, write: if request.auth.uid == uid;
      }
    }
    match /scores_monthly/{month}/users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
    }
  }
}
```

## Очки

`пары × 10 − время/30 − ошибки × 2 + бонус за скорость`  
Подсказка: −10, Перемешать: −20, Отмена: −5

## Генерация уровней

8 алгоритмов × случайные параметры = тысячи уникальных форм.  
Каждая игра гарантированно решаема.
