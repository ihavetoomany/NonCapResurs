//
//  ContentView.swift
//  NonCapResurs
//
//  Created by Bjarne Werner on 2025-11-20.
//

import SwiftUI

// Shared SEK currency format with no fractional digits
private let sekNoFraction: FloatingPointFormatStyle<Double>.Currency =
    .currency(code: "SEK").precision(.fractionLength(0))

// Wallet (purse) symbol: use the bifold wallet on iOS 17+, fall back to wallet.pass on iOS 16
private var walletSymbolName: String {
    if #available(iOS 17.0, *) { return "wallet.bifold" } else { return "wallet.pass" }
}

struct ContentView: View {
    var body: some View {
        TabView {
            WalletTabView()
                .tabItem {
                    Label("Overview", systemImage: "wallet.pass")
                }

            EngagementsTabView()
                .tabItem {
                    Label("Wallet", systemImage: walletSymbolName)
                }

            ExploreTabView()
                .tabItem {
                    Label("Explore", systemImage: "safari")
                }

            SupportTabView()
                .tabItem {
                    Label("Support", systemImage: "ellipsis.bubble")
                }
        }
    }
}

private struct WalletTabView: View {
    private var totalToPay: Double {
        invoicesToPay.reduce(0) { $0 + $1.amount }
    }

    private var toPayCount: Int {
        invoicesToPay.count
    }

    var body: some View {
        NavigationStack {
            List {
                // Summary card fills full row width by removing default content insets
                Section {
                    WalletSummaryCard(total: totalToPay, count: toPayCount)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowInsets(EdgeInsets())           // remove content padding
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section("To Pay") {
                    ForEach(invoicesToPay) { invoice in
                        InvoiceRow(invoice: invoice)
                            .listRowBackground(Rectangle().fill(.ultraThinMaterial))
                    }
                }

                Section("Handled") {
                    ForEach(invoicesHandled) { invoice in
                        InvoiceRow(invoice: invoice)
                            .listRowBackground(Rectangle().fill(.ultraThinMaterial))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Overview")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Add action here
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .background(
                // Subtle glassy backdrop
                ZStack {
                    Color.clear
                    Rectangle().fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                        .opacity(0.0) // keep list default; material used per-row/toolbar
                }
            )
        }
    }
}

private struct EngagementsTabView: View {

    // Caption to show beneath the trailing amount per engagement.
    // Custom overrides per account name as requested.
    private func amountCaption(for item: AccountItem) -> String {
        switch item.name {
        case "Netonnet":
            return "not billed"
        case "Bauhaus":
            return "not billed"
        case "Power", "Jula":
            return "paid"
        default:
            // Fallback to type-based captions
            switch item.type {
            case .loan: return "debt"
            case .saving: return "balance"
            case .buyNowPayLater: return "debt"
            case .storeCredit: return "available"
            case .universalCredit, .universalHybrid: return ""
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // "Cards" section with a horizontal carousel of credit cards
                Section {
                    if #available(iOS 17.0, *) {
                        ScrollView(.horizontal) {
                            HStack(spacing: 16) {
                                ForEach(sampleCards) { card in
                                    CreditCardView(card: card)
                                }
                            }
                            .scrollTargetLayout() // mark children as scroll targets for snapping
                        }
                        .contentMargins(.horizontal, 0, for: .scrollContent) // keep carousel position
                        .scrollTargetBehavior(.viewAligned) // snap each card to center
                        .scrollIndicators(.hidden)
                    } else {
                        // iOS 16 fallback: page-style TabView (snaps per page)
                        TabView {
                            ForEach(sampleCards) { card in
                                CreditCardView(card: card)
                            }
                        }
                        .frame(height: 190)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .padding(.horizontal, 16) // keep carousel position
                    }
                } header: {
                    Text("Universal Credit")
                        .padding(.leading, 16) // shift title 16pt to the right
                }
                // Remove row insets so our own margins control the content
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // Store Credit section (exclude Universal types, Savings and Loan)
                Section("Store Credit") {
                    ForEach(accounts.filter { ($0.type != .universalCredit && $0.type != .universalHybrid) && ($0.type != .saving && $0.type != .loan) }) { item in
                        let caption = amountCaption(for: item)
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .foregroundStyle(.tint)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                Text(item.type.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(item.balance, format: sekNoFraction)
                                    .font(.callout)
                                    .foregroundStyle(item.type == .saving ? .green : .primary)
                                Text(caption)
                                    .font(.caption2)
                                    .foregroundStyle(caption == "paid" ? .green : .secondary)
                            }

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .listRowBackground(Rectangle().fill(.ultraThinMaterial))
                    }
                }

                // Finance section (Savings and Loan)
                Section("Finance") {
                    ForEach(accounts.filter { $0.type == .saving || $0.type == .loan }) { item in
                        let caption = amountCaption(for: item)
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .foregroundStyle(.tint)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                Text(item.type.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(item.balance, format: sekNoFraction)
                                    .font(.callout)
                                    .foregroundStyle(item.type == .saving ? .green : .primary)
                                Text(caption)
                                    .font(.caption2)
                                    .foregroundStyle(caption == "paid" ? .green : .secondary)
                            }

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .listRowBackground(Rectangle().fill(.ultraThinMaterial))
                    }
                }
            }
            .navigationTitle("Wallet")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
}

private struct ExploreTabView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Discover")
                                .font(.headline)
                            Text("Find new opportunities and insights tailored for you.")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trending")
                                .font(.headline)
                            HStack {
                                Label("Popular Now", systemImage: "flame")
                                Spacer()
                                Label("Nearby", systemImage: "location")
                            }
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        }
                    }
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommendations")
                                .font(.headline)
                            Text("Personalized picks based on your activity.")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
            }
            .background(
                // Subtle layered glass look
                LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
                    .background(.ultraThinMaterial) // material sits behind scroll content
                    .ignoresSafeArea()
            )
            .navigationTitle("Explore")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
}

private struct SupportTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(
                        destination:
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Contact Support")
                                    .font(.title3).bold()
                                Text("We’re here to help. Choose a method below.")
                                    .foregroundStyle(.secondary)
                                Divider()
                                Label("Start a Chat", systemImage: "message.circle")
                                Label("Email Us", systemImage: "envelope.circle")
                                Label("Call Support", systemImage: "phone.circle")
                                Spacer()
                            }
                            .padding()
                            .navigationTitle("Contact")
                            .toolbarBackground(.ultraThinMaterial, for: .navigationBar),
                        label: {
                            Label("Contact", systemImage: "person.crop.circle.badge.questionmark")
                        }
                    )
                    .listRowBackground(Rectangle().fill(.ultraThinMaterial))

                    NavigationLink(
                        destination:
                            VStack(alignment: .leading, spacing: 12) {
                                Text("FAQ")
                                    .font(.title3).bold()
                                Text("Common questions and quick answers.")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding()
                            .navigationTitle("FAQ")
                            .toolbarBackground(.ultraThinMaterial, for: .navigationBar),
                        label: {
                            Label("FAQ", systemImage: "questionmark.circle")
                        }
                    )
                    .listRowBackground(Rectangle().fill(.ultraThinMaterial))
                } header: {
                    Text("Support")
                }
            }
            .navigationTitle("Support")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
}

// MARK: - Reusable "Glass" components (system materials only)

private struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.15))
            )
            // Drop shadow removed per request
    }
}

// MARK: - Credit cards carousel

private struct CreditCard: Identifiable {
    let id = UUID()
    let name: String
    let available: Double
    let pin: String
}

private let sampleCards: [CreditCard] = [
    .init(name: "Resurs Gold",   available: 25000, pin: "4321"),
    .init(name: "Resurs Family", available: 18000, pin: "2468"),
    .init(name: "Gekås MC",      available: 12000, pin: "1357")
]

private struct CreditCardView: View {
    let card: CreditCard
    @State private var showPIN = false

    var body: some View {
        ZStack {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(card.name)
                            .font(.headline)
                        Spacer()
                        // small brand glyph
                        Image(systemName: "creditcard.fill")
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(card.available, format: sekNoFraction)
                            .font(.title3).bold()
                    }

                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut) { showPIN = true }
                        } label: {
                            Label("Show PIN", systemImage: "key.fill")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: 300, height: 170)
        .overlay {
            if showPIN {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(.white.opacity(0.2))
                        )

                    VStack(spacing: 10) {
                        Text("PIN")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(card.pin)
                            .font(.title2).bold()
                            .monospacedDigit()

                        Button {
                            withAnimation(.easeInOut) { showPIN = false }
                        } label: {
                            Label("Hide", systemImage: "eye.slash.fill")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.thinMaterial, in: Capsule())
                        }
                        .padding(.top, 6)
                    }
                    .padding()
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Wallet summary

private struct WalletSummaryCard: View {
    let total: Double
    let count: Int

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Overview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("Part pay available", systemImage: "divide.circle")
                        .font(.caption2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                }

                HStack(alignment: .firstTextBaseline) {
                    Text(total, format: sekNoFraction)
                        .font(.title3).bold()
                    Spacer()
                    Text("\(count) invoices")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Accounts list data (Engagements)

private enum EngagementType: String {
    case storeCredit       = "Store credit"
    case universalCredit   = "Universal credit"
    case buyNowPayLater    = "Buy now pay later"
    case loan              = "Loan"
    case saving            = "Savings"
    case universalHybrid   = "Universal hybrid"
}

private struct AccountItem: Identifiable {
    let id = UUID()
    let icon: String
    let name: String
    let type: EngagementType
    let balance: Double
}

private let accounts: [AccountItem] = [
    .init(icon: "creditcard",        name: "Resurs Gold",      type: .universalCredit, balance: 12450),
    .init(icon: "creditcard",        name: "Resurs Family",    type: .universalHybrid, balance: 9300),
    .init(icon: "creditcard",        name: "Gekås MC",         type: .universalCredit, balance: 6700),
    .init(icon: "building.columns",  name: "Garden Upgrade",   type: .loan,            balance: 125000),
    .init(icon: "chart.line.uptrend.xyaxis", name: "New Car",  type: .saving,          balance: 45230),
    .init(icon: "divide.circle",     name: "Netonnet",         type: .buyNowPayLater,  balance: 3200),
    .init(icon: "bag",               name: "Bauhaus",          type: .storeCredit,     balance: 1250),
    .init(icon: "bag",               name: "Power",            type: .storeCredit,     balance: 2200),
    .init(icon: "bag",               name: "Jula",             type: .storeCredit,     balance: 5400)
]

// MARK: - Invoices data and rows

private struct Invoice: Identifiable {
    enum Status {
        case toPay
        case handled
    }

    let id = UUID()
    let vendor: String
    let date: Date
    let amount: Double
    let status: Status
}

private struct InvoiceRow: View {
    let invoice: Invoice

    var body: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundStyle(invoice.status == .handled ? .green : .orange)

            VStack(alignment: .leading) {
                Text(invoice.vendor)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(invoice.amount, format: sekNoFraction)
                .font(.callout)
                .foregroundStyle(invoice.status == .handled ? .green : .primary)

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        switch invoice.status {
        case .toPay:
            return "Due " + invoice.date.formatted(.dateTime.month(.abbreviated).day())
        case .handled:
            return "Paid " + invoice.date.formatted(.dateTime.month(.abbreviated).day())
        }
    }
}

private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
}

private let invoicesToPay: [Invoice] = [
    .init(vendor: "Acme Utilities", date: makeDate(2025, 11, 25), amount: 89.99, status: .toPay),
    .init(vendor: "Nordic Internet", date: makeDate(2025, 11, 28), amount: 59.00, status: .toPay),
    .init(vendor: "City Parking", date: makeDate(2025, 11, 22), amount: 12.50, status: .toPay),
    .init(vendor: "Gym Membership", date: makeDate(2025, 12, 1), amount: 39.00, status: .toPay),
    .init(vendor: "Green Energy", date: makeDate(2025, 12, 3), amount: 114.25, status: .toPay),
    .init(vendor: "Mobile Plan", date: makeDate(2025, 11, 30), amount: 29.99, status: .toPay)
]

private let invoicesHandled: [Invoice] = [
    .init(vendor: "Cloud Storage", date: makeDate(2025, 11, 10), amount: 9.99, status: .handled),
    .init(vendor: "Streaming Service", date: makeDate(2025, 11, 08), amount: 14.99, status: .handled),
    .init(vendor: "Office Supplies", date: makeDate(2025, 11, 05), amount: 23.45, status: .handled),
    .init(vendor: "Ride Share", date: makeDate(2025, 11, 02), amount: 18.20, status: .handled),
    .init(vendor: "Food Delivery", date: makeDate(2025, 11, 01), amount: 27.30, status: .handled),
    .init(vendor: "Domain Renewal", date: makeDate(2025, 10, 29), amount: 11.99, status: .handled)
]

#Preview {
    ContentView()
}
