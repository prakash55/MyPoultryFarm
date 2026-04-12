//
//  BatchLogsTab.swift
//  MyPoultryFarm
//

import SwiftUI

struct BatchLogsTab: View {
    @ObservedObject var vm: BatchDetailViewModel

    var body: some View {
        VStack(spacing: 12) {
            if !vm.batchLogs.isEmpty {
                HStack(spacing: 0) {
                    miniStat(icon: "exclamationmark.triangle.fill", value: "\(vm.totalMortality)", label: "Died", color: .red)
                    miniDivider
                    miniStat(icon: "leaf.fill", value: "\(String(format: "%.0f", vm.batchLogs.reduce(0.0) { $0 + $1.feedUsedBags })) bags", label: "Feed", color: .orange)
                    miniDivider
                    let medCount = vm.batchLogs.filter { $0.medicineUsed != nil && !($0.medicineUsed?.isEmpty ?? true) }.count
                    miniStat(icon: "cross.case.fill", value: "\(medCount)", label: "Meds", color: .purple)
                    let weightLogs = vm.batchLogs.filter { $0.avgWeightKg > 0 }
                    if !weightLogs.isEmpty {
                        miniDivider
                        let latestWeight = weightLogs.sorted(by: { $0.logDate > $1.logDate }).first!.avgWeightKg
                        miniStat(icon: "scalemass.fill", value: "\(String(format: "%.2f", latestWeight)) kg", label: "Wt", color: .teal)
                    }
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [Color(.systemBackground), Color.blue.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.15), lineWidth: 1))
                )
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }

            if vm.daySummaries.isEmpty {
                emptyState(icon: "list.clipboard", message: "No daily logs yet")
            } else {
                ForEach(vm.daySummaries) { day in
                    dayCard(day)
                }
            }
        }
    }

    // MARK: - Helpers

    private var miniDivider: some View { Divider().frame(height: 24) }

    private func miniStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.caption2).foregroundStyle(color)
                Text(value).font(.subheadline.weight(.bold)).foregroundStyle(color)
            }
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func dayCard(_ day: DaySummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(vm.relativeDay(day.date)).font(.subheadline.weight(.bold)).foregroundStyle(.blue)
                Text("·").foregroundStyle(.secondary)
                Text(vm.shortDate(day.date)).font(.subheadline).foregroundStyle(.secondary)
                if day.logCount > 1 {
                    Text("(\(day.logCount) entries)").font(.caption).foregroundStyle(.tertiary)
                }
                Spacer()
            }

            HStack(spacing: 16) {
                if day.totalMortality > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.caption2).foregroundStyle(.red)
                        Text("\(day.totalMortality) died").font(.subheadline.weight(.medium)).foregroundStyle(.red)
                    }
                }
                if day.totalFeedBags > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill").font(.caption2).foregroundStyle(.orange)
                        Text("\(String(format: "%.1f", day.totalFeedBags)) bags").font(.subheadline.weight(.medium))
                        if !day.feedTypes.isEmpty {
                            Text(day.feedTypes.map { $0.capitalized }.joined(separator: ", ")).font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
                Spacer()
            }

            if !day.medicines.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "cross.case.fill").font(.caption2).foregroundStyle(.purple)
                    let medText = day.medicines.map { "\($0.name)\($0.qty > 0 ? " (\(String(format: "%.0f", $0.qty)))" : "")" }
                    Text(medText.joined(separator: ", ")).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
            }

            if day.avgWeight > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "scalemass.fill").font(.caption2).foregroundStyle(.teal)
                    Text("\(String(format: "%.2f", day.avgWeight)) kg avg").font(.subheadline.weight(.medium)).foregroundStyle(.teal)
                }
            }

            let dayNotes = day.logs.compactMap(\.notes).filter { !$0.isEmpty }
            if !dayNotes.isEmpty {
                Text(dayNotes.joined(separator: " · ")).font(.caption).foregroundStyle(.tertiary).lineLimit(1)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [Color(.systemBackground), Color.blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.12), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(.quaternary)
            Text(message).font(.subheadline).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
    }
}
