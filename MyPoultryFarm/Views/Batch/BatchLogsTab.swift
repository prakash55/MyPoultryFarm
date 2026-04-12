//
//  BatchLogsTab.swift
//  MyPoultryFarm
//

import SwiftUI

struct BatchLogsTab: View {
    @ObservedObject var vm: BatchDetailViewModel

    private var latestWeight: Double? {
        vm.batchLogs.filter { $0.avgWeightKg > 0 }.sorted(by: { $0.logDate > $1.logDate }).first?.avgWeightKg
    }

    private var medCount: Int {
        vm.batchLogs.filter { $0.medicineUsed != nil && !($0.medicineUsed?.isEmpty ?? true) }.count
    }

    private var mortalityPct: String {
        vm.batch.computedTotalBirds > 0
            ? String(format: "%.1f%%", Double(vm.totalMortality) / Double(vm.batch.computedTotalBirds) * 100) : "0%"
    }

    var body: some View {
        VStack(spacing: 14) {
            logsHeroCard
            metricsStrip

            if vm.daySummaries.isEmpty {
                emptyState(icon: "list.clipboard", message: "No daily logs yet")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Daily Logs")
                        .font(.subheadline.weight(.semibold))
                    ForEach(vm.daySummaries) { day in
                        dayCard(day)
                    }
                }
            }
        }
    }

    // MARK: - Hero Card

    private var logsHeroCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Mortality")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.65))
                    Text("\(vm.totalMortality)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(vm.daySummaries.count) Days")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.15)))

                    Text(mortalityPct + " of flock")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 16)

            HStack(spacing: 0) {
                heroStat(value: "\(vm.totalMortality)", label: "Died", icon: "exclamationmark.triangle.fill", color: .red)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
                heroStat(value: vm.quantityText(vm.totalFeedUsed, unit: vm.feedInventoryUnit), label: "Feed Used", icon: "leaf.fill", color: .yellow)
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 32)
                heroStat(value: latestWeight != nil ? String(format: "%.2f kg", latestWeight!) : "—", label: "Weight", icon: "scalemass.fill", color: .cyan)
            }
            .padding(.vertical, 12)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.30, blue: 0.60), Color(red: 0.15, green: 0.40, blue: 0.70)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func heroStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundStyle(color)
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Metrics Strip

    private var metricsStrip: some View {
        HStack(spacing: 10) {
            metricPill(title: "Mortality %", value: mortalityPct, color: .red)
            metricPill(title: "Medicines", value: "\(medCount)", color: .purple)
            metricPill(title: "Avg Weight", value: latestWeight != nil ? String(format: "%.2f kg", latestWeight!) : "—", color: .teal)
        }
    }

    private func metricPill(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.caption.weight(.bold)).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.7)
            Text(title).font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(color.opacity(0.15), lineWidth: 1))
        )
    }

    // MARK: - Day Card

    private func dayCard(_ day: DaySummary) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(vm.relativeDay(day.date))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.blue)
                Text(vm.shortDate(day.date))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if day.totalMortality > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 9)).foregroundStyle(.red)
                            Text("\(day.totalMortality) died").font(.caption.weight(.medium)).foregroundStyle(.red)
                        }
                    }
                    if day.totalFeedBags > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "leaf.fill").font(.system(size: 9)).foregroundStyle(.orange)
                            Text("\(String(format: "%.1f", day.totalFeedBags)) bags").font(.caption.weight(.medium))
                        }
                    }
                    if day.avgWeight > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "scalemass.fill").font(.system(size: 9)).foregroundStyle(.teal)
                            Text("\(String(format: "%.2f", day.avgWeight)) kg").font(.caption.weight(.medium)).foregroundStyle(.teal)
                        }
                    }
                }

                if !day.medicines.isEmpty {
                    let medText = day.medicines.map { "\($0.name)\($0.qty > 0 ? " (\(String(format: "%.0f", $0.qty)))" : "")" }
                    HStack(spacing: 3) {
                        Image(systemName: "cross.case.fill").font(.system(size: 9)).foregroundStyle(.purple)
                        Text(medText.joined(separator: ", ")).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }

                let dayNotes = day.logs.compactMap(\.notes).filter { !$0.isEmpty }
                if !dayNotes.isEmpty {
                    Text(dayNotes.joined(separator: " · ")).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                }
            }

            Spacer()

            if day.logCount > 1 {
                Text("\(day.logCount)")
                    .font(.caption2.weight(.bold)).foregroundStyle(.blue)
                    .frame(width: 22, height: 22)
                    .background(Color.blue.opacity(0.1), in: Circle())
            }
        }
        .padding(12)
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.blue.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.blue.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(.quaternary)
            Text(message).font(.subheadline).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
    }
}
