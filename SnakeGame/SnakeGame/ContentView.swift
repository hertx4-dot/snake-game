import SwiftUI

struct Point: Hashable {
    var x: Int
    var y: Int
}

struct ContentView: View {
    let gridSize = 20
    @State private var snake: [Point] = [Point(x: 10, y: 10)]
    @State private var direction: Point = Point(x: 1, y: 0)
    @State private var pendingDirection: Point = Point(x: 1, y: 0)
    @State private var food: Point = Point(x: 15, y: 10)
    @State private var score = 0
    @State private var best = UserDefaults.standard.integer(forKey: "snake_best")
    @State private var isGameOver = false
    @State private var isPaused = false

    let timer = Timer.publish(every: 0.14, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) - 40
            let cell = side / CGFloat(gridSize)

            ZStack {
                LinearGradient(colors: [Color(red: 0.06, green: 0.07, blue: 0.09),
                                        Color(red: 0.10, green: 0.12, blue: 0.16)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("СЧЁТ").font(.caption).foregroundColor(.gray)
                            Text("\(score)").font(.title2).bold().foregroundColor(.white)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("РЕКОРД").font(.caption).foregroundColor(.gray)
                            Text("\(best)").font(.title2).bold().foregroundColor(.yellow)
                        }
                    }
                    .frame(width: side)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.4))

                        Path { path in
                            for i in 0...gridSize {
                                let pos = CGFloat(i) * cell
                                path.move(to: CGPoint(x: pos, y: 0))
                                path.addLine(to: CGPoint(x: pos, y: side))
                                path.move(to: CGPoint(x: 0, y: pos))
                                path.addLine(to: CGPoint(x: side, y: pos))
                            }
                        }
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.5)

                        // Еда
                        Circle()
                            .fill(RadialGradient(colors: [.red, .orange],
                                                 center: .center, startRadius: 0, endRadius: cell))
                            .frame(width: cell * 0.85, height: cell * 0.85)
                            .position(x: (CGFloat(food.x) + 0.5) * cell,
                                      y: (CGFloat(food.y) + 0.5) * cell)

                        // Змейка
                        ForEach(Array(snake.enumerated()), id: \.offset) { index, p in
                            RoundedRectangle(cornerRadius: cell * 0.25)
                                .fill(index == 0
                                      ? Color(red: 0.31, green: 0.55, blue: 1.0)
                                      : Color(red: 0.20, green: 0.40, blue: 0.85))
                                .frame(width: cell - 1.5, height: cell - 1.5)
                                .position(x: (CGFloat(p.x) + 0.5) * cell,
                                          y: (CGFloat(p.y) + 0.5) * cell)
                        }
                    }
                    .frame(width: side, height: side)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .gesture(
                        DragGesture(minimumDistance: 15)
                            .onEnded { value in
                                let dx = value.translation.width
                                let dy = value.translation.height
                                if abs(dx) > abs(dy) {
                                    if dx > 0 { trySetDirection(Point(x: 1, y: 0)) }
                                    else      { trySetDirection(Point(x: -1, y: 0)) }
                                } else {
                                    if dy > 0 { trySetDirection(Point(x: 0, y: 1)) }
                                    else      { trySetDirection(Point(x: 0, y: -1)) }
                                }
                            }
                    )

                    HStack(spacing: 14) {
                        Button(isPaused ? "▶ Продолжить" : "⏸ Пауза") {
                            isPaused.toggle()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        Button("↻ Заново") { reset() }
                            .buttonStyle(.bordered)
                            .tint(.gray)
                    }
                    .frame(width: side)
                    .padding(.bottom, 8)
                }
                .padding(.vertical, 20)

                if isGameOver {
                    Color.black.opacity(0.75).ignoresSafeArea()
                    VStack(spacing: 22) {
                        Text("ИГРА ОКОНЧЕНА")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundColor(.red)
                        VStack(spacing: 6) {
                            Text("Счёт: \(score)").font(.title2).foregroundColor(.white)
                            if score >= best && score > 0 {
                                Text("🏆 Новый рекорд!")
                                    .foregroundColor(.yellow).font(.headline)
                            }
                        }
                        Button("Играть снова") { reset() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(.blue)
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            if !isGameOver && !isPaused {
                direction = pendingDirection
                step()
            }
        }
    }

    func trySetDirection(_ newDir: Point) {
        // запрет разворота на 180°
        if newDir.x == -direction.x && newDir.y == -direction.y { return }
        pendingDirection = newDir
    }

    func step() {
        guard let head = snake.first else { return }
        let newHead = Point(x: head.x + direction.x, y: head.y + direction.y)

        if newHead.x < 0 || newHead.x >= gridSize ||
           newHead.y < 0 || newHead.y >= gridSize {
            gameOver()
            return
        }

        if snake.dropLast().contains(newHead) {
            gameOver()
            return
        }

        snake.insert(newHead, at: 0)
        if newHead == food {
            score += 1
            if score > best {
                best = score
                UserDefaults.standard.set(best, forKey: "snake_best")
            }
            spawnFood()
        } else {
            snake.removeLast()
        }
    }

    func gameOver() {
        isGameOver = true
    }

    func spawnFood() {
        var p: Point
        repeat {
            p = Point(x: Int.random(in: 0..<gridSize),
                      y: Int.random(in: 0..<gridSize))
        } while snake.contains(p)
        food = p
    }

    func reset() {
        snake = [Point(x: 10, y: 10)]
        direction = Point(x: 1, y: 0)
        pendingDirection = Point(x: 1, y: 0)
        score = 0
        isGameOver = false
        isPaused = false
        spawnFood()
    }
}
