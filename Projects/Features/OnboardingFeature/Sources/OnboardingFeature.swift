import ComposableArchitecture
import SwiftUI

@Reducer
public struct OnboardingFeature {
    public struct State: Equatable {
        public init() {}
    }

    public enum Action: Equatable {
        case continueButtonTapped
        case delegate(Delegate)
    }

    public enum Delegate: Equatable {
        case didFinishOnboarding
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .continueButtonTapped:
                return .send(.delegate(.didFinishOnboarding))

            case .delegate:
                return .none
            }
        }
    }
}

public struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    heroCard
                    routineCard
                    continueButton(viewStore: viewStore)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .background(OnboardingStyle.background.ignoresSafeArea())
            .navigationTitle("환영합니다")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("원두노트")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(OnboardingStyle.espresso)

            Text("원두마다 쌓이는 나의 커피 기록")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(OnboardingStyle.olive)
        }
        .padding(.bottom, 8)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("첫 원두를 등록하고")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OnboardingStyle.caramel)

                    Text("몇 잔째인지\n바로 확인하세요")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(OnboardingStyle.pearl)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(OnboardingStyle.espresso)
                    .frame(width: 58, height: 58)
                    .background(OnboardingStyle.caramel, in: Circle())
            }

            Text("원두별로 마신 누적 잔 수를 보여줍니다.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(OnboardingStyle.pearl.opacity(0.82))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                statusPill("원두 등록")
                statusPill("한 잔 기록")
                statusPill("잔 수 확인")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OnboardingStyle.espresso, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: OnboardingStyle.espresso.opacity(0.2), radius: 20, x: 0, y: 14)
    }

    private var routineCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("시작은 간단하게")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(OnboardingStyle.espresso)

            VStack(alignment: .leading, spacing: 14) {
                routineRow(
                    systemName: "shippingbox.fill",
                    title: "첫 원두 등록",
                    description: "이름, 로스터, 용량만 먼저 적어두세요."
                )
                routineRow(
                    systemName: "plus.circle.fill",
                    title: "커피 한 잔 기록",
                    description: "마실 때마다 사용량을 빠르게 남깁니다."
                )
                routineRow(
                    systemName: "chart.bar.xaxis",
                    title: "원두별 잔 수 확인",
                    description: "현재 원두로 몇 잔째인지 홈에서 바로 봅니다."
                )
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(OnboardingStyle.pearl.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: OnboardingStyle.espresso.opacity(0.04), radius: 12, x: 0, y: 8)
    }

    private func routineRow(systemName: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(OnboardingStyle.caramel)
                .frame(width: 34, height: 34)
                .background(OnboardingStyle.pampas, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingStyle.espresso)

                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(OnboardingStyle.olive)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func continueButton(
        viewStore: ViewStore<OnboardingFeature.State, OnboardingFeature.Action>
    ) -> some View {
        Button {
            viewStore.send(.continueButtonTapped)
        } label: {
            HStack(spacing: 10) {
                Text("첫 원두 등록하기")
                    .font(.system(size: 16, weight: .bold, design: .rounded))

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(OnboardingStyle.pearl)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(OnboardingStyle.espresso, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: OnboardingStyle.espresso.opacity(0.18), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityHint("온보딩을 마치고 원두 창고로 이동합니다.")
    }

    private func statusPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(OnboardingStyle.pearl)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.12), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
    }
}

private enum OnboardingStyle {
    static let espresso = Color(red: 0.212, green: 0.145, blue: 0.106)
    static let caramel = Color(red: 0.761, green: 0.498, blue: 0.361)
    static let pearl = Color(red: 0.91, green: 0.886, blue: 0.851)
    static let pampas = Color(red: 0.961, green: 0.949, blue: 0.933)
    static let background = Color(red: 0.988, green: 0.98, blue: 0.973)
    static let olive = Color(red: 0.451, green: 0.498, blue: 0.416)
}
