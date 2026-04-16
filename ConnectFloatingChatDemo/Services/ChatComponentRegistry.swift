import SwiftUI

@MainActor
final class ChatComponentRegistry: ObservableObject {
    typealias Factory = (ChatEmbeddedComponent) -> AnyView

    private var factories: [String: Factory] = [:]

    init() {
        registerDefaults()
    }

    func register(componentKey: String, factory: @escaping Factory) {
        factories[componentKey] = factory
    }

    func register<Payload: Decodable, Content: View>(
        componentKey: String,
        payloadType: Payload.Type,
        @ViewBuilder factory: @escaping (ChatEmbeddedComponent, Payload) -> Content
    ) {
        factories[componentKey] = { component in
            guard let payload = ChatComponentPayloadCoder.decode(payloadType, from: component) else {
                return AnyView(UnsupportedPayloadCard(component: component))
            }

            return AnyView(factory(component, payload))
        }
    }

    func view(for component: ChatEmbeddedComponent) -> AnyView {
        if let factory = factories[component.componentKey] {
            return factory(component)
        }

        return AnyView(UnsupportedComponentCard(component: component))
    }

    private func registerDefaults() {
        register(componentKey: "hotel-carousel", payloadType: [HotelCardItem].self) { component, hotels in
            SampleHotelCarouselComponent(component: component, hotels: hotels)
        }
    }
}

private struct UnsupportedComponentCard: View {
    let component: ChatEmbeddedComponent

    var body: some View {
        Text("No registered SwiftUI view for component key `\(component.componentKey)`.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.95, green: 0.96, blue: 0.99))
            )
    }
}

private struct SampleHotelCarouselComponent: View {
    let component: ChatEmbeddedComponent
    let hotels: [HotelCardItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(component.title)
                .font(.headline.weight(.semibold))

            if let subtitle = component.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(hotels) { hotel in
                        HotelCarouselCard(hotel: hotel)
                    }
                }
            }
        }
    }
}

private struct UnsupportedPayloadCard: View {
    let component: ChatEmbeddedComponent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Component payload mismatch")
                .font(.footnote.weight(.semibold))
            Text("`\(component.componentKey)` was registered, but the payload could not be decoded into the expected SwiftUI view model.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.99, green: 0.96, blue: 0.94))
        )
    }
}

private struct HotelCarouselCard: View {
    let hotel: HotelCardItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(hotel.badgeText.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)

            Text(hotel.name)
                .font(.headline)
                .lineLimit(2)

            Text(hotel.location)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(hotel.ratingText)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)

            Text(hotel.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer(minLength: 0)

            HStack {
                Text(hotel.nightlyPrice)
                    .font(.headline.weight(.bold))

                Spacer()

                Button("View") {
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 250, height: 220, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
    }
}
