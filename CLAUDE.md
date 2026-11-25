# Mussel — rules for Claude

An iOS app for complete gym beginners: a 12-week program in three phases (machines → dumbbells → barbell), and every exercise shown as an animated figure on its machine with the working muscles lit. Third app by Leon after Nomaded and Stepity.

## Before a task

- The program, the weight rules and the safety rules are in the coach doc «Программы для новичков — черновик для тренеров»: https://claude.ai/artifact/4KwpdWsjsqcFd8tGibGMgm (Claude Docs). The programs in `Domain/Program.swift` and the cues in `Domain/Technique.swift` are drafts until the coaches review them in the app.
- The coaches asked to see the app first and review the program in it.

## Communication

- Answer Leon in Russian. Code, identifiers and comments in English.
- Leon is new to iOS: explain a new iOS/Swift concept in 1–2 sentences.
- For a product or design decision, give one option with a recommendation.

## Build and check

After code changes, always check the build and the tests:

```bash
xcodebuild -project Mussel.xcodeproj -scheme Mussel \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' -quiet build

xcodebuild -project Mussel.xcodeproj -scheme Mussel \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' -quiet test
```

- No errors and no new warnings.
- Tests boot their own simulator clone and shut the simulator down; boot it again before screenshots.

## Rules

- **Don't commit or push.** Leon commits. You may suggest a commit message (Conventional Commits, English).
- **No third-party dependencies** without Leon's consent.
- **Project files:** `Mussel/` and `MusselTests/` are synchronized folders (Xcode 16+). Create files in the right subfolder; don't touch `project.pbxproj`.
- **Swift 6, iOS 18.** Strict concurrency.
- **Domain logic gets tests** (Swift Testing, `MusselTests/`). `Domain/` is plain Swift without UI.
- **Design tokens** (`Palette`, `Typography`, `Motion`, `Haptics`, `.card()`, `.demoStage()`, `Chip`, `Eyebrow`) instead of magic numbers. Dark only. Coral is for working muscles and primary actions; each level/phase has its own color (`Palette.level`).
- **Strings:** an English key in `Text("…")` / `String(localized:)` and its Russian translation in `Mussel/Resources/Localizable.xcstrings` right away (plurals where there's a number). Address the user as «ты», without gendered forms.
- **Reduce Motion:** demos show one still frame (the turn of the rep over a faint start).

## Workouts and weights

- `Domain/Coach.swift` — the rules from the coach doc: the next workout (A/B turns, phases of ≥4 weeks and ≥75% of their workouts, week 1 = 2 sets), the first weight (lightest, then «0–1 / 2–3 / 4+» set by set, max 4 trial sets; «4+» on the first set = two steps), progression after «Легко / Нормально / Тяжело», breaks (2–3 weeks −10%, 4+ weeks −20% and the phase restarts), «Болит» (swap next time; pain again → see a doctor).
- `Domain/WorkoutRun.swift` — a workout in progress as a state machine (`stage`: lifting, repsLeft, feeling, resting, finished). `Features/Workout/` only shows it.
- `Data/TrainingStore.swift` — the log as JSON in Application Support, on the device only.
- Every rule change goes with a test in `CoachTests` / `WorkoutRunTests`.

## Demos (the animated figures)

- `Demo/Pose.swift` — a pose: hip, torso, limbs by angle (`.bones`), by target with two-bone IK (`.reach`), or as screen vectors (`.flat`, for arms swinging towards the camera). Angles: 0 down, 90 forward, 180 up.
- `Demo/Skeleton.swift` — solves a pose into points; body proportions in `Body`.
- `Demo/Demo.swift` — a demo: start pose, one or two turn poses, tempo (`liftFirst` / `lowerFirst` / `hold`), props (seats, stacks, cables, levers, plates) anchored to the scene, to the load or to bones.
- `Demo/DemoLibrary*.swift` — one demo per exercise. `Gym` has the shared furniture.
- `Demo/DemoRenderer.swift` + `DemoView.swift` — drawing in a SwiftUI `Canvas`.
- After adding or changing a demo, render it with `Tools/DemoSheets` and look at the PNG; `DemoTests` checks that hands and feet reach their targets.

## Checking screens without tapping (DEBUG launch arguments)

```bash
xcrun simctl launch --terminate-running-process "iPhone 16 Pro" com.leonkazaryan.mussel \
  -AppleLanguages "(ru)" -AppleLocale ru_RU -MusselDebugScreen exercise -MusselDebugExercise legPress
xcrun simctl io "iPhone 16 Pro" screenshot shot.png
```

- `-MusselDebugScreen onboarding|program|library|exercise|workout|profile`, `-MusselDebugOnboardingStep 0…6`, `-MusselDebugExercise <ExerciseID>`, `-MusselDebugPhase 0|1|2`, `-MusselDebugDays 2|3|4`, `-MusselDebugReset YES` (forget onboarding and the training log).
- `-MusselDebugWorkoutStage repsLeft|rest|feeling|summary` with `-MusselDebugScreen workout`: the workout plays itself up to that point. `summary` saves a real workout to the log.

## Environment

- Xcode 27.2, simulators iOS 18.6 (iPhone 16 Pro, main), 26.x, 27.2.
- Bundle ID `com.leonkazaryan.mussel`, team `A577864FRK`.
- Repository: https://github.com/LeonKazaryan/gymapp (remote `origin`, branch `main`).
