import Foundation

/// Merges SwiftFormat configuration files
public enum ConfigMerger {
    /// Merge base config with overrides
    ///
    /// - Parameters:
    ///   - baseConfig: URL of base configuration file
    ///   - overrides: URL of overrides file
    /// - Returns: Merged configuration content
    /// - Throws: Error if files cannot be read
    public static func mergeSwiftFormatConfigs(baseConfig: URL, overrides: URL) throws -> String {
        let baseContent = try String(contentsOf: baseConfig, encoding: .utf8)
        let overrideContent = try String(contentsOf: overrides, encoding: .utf8)

        // Parse base config into a dictionary of rules
        var rules = parseSwiftFormatConfig(baseContent)

        // Parse override config
        let overrideRules = parseSwiftFormatConfig(overrideContent)

        // Merge overrides into base (overrides take precedence)
        for (key, value) in overrideRules {
            rules[key] = value
        }

        // Reconstruct config file
        return reconstructSwiftFormatConfig(rules, baseContent: baseContent, overrideContent: overrideContent)
    }

    /// Parse SwiftFormat config into rule dictionary
    ///
    /// Keys are namespaced to avoid conflicts:
    /// - "rule:redundantSelf" for --rules/--disable
    /// - "option:indent" for configuration options
    /// Values are:
    /// - For --rules: "enabled"
    /// - For --disable: "disabled"
    /// - For options: the value (e.g., "--indent 4" -> ["option:indent": "4"])
    private static func parseSwiftFormatConfig(_ content: String) -> [String: String] {
        var rules: [String: String] = [:]

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Parse --rules lines
            if trimmed.hasPrefix("--rules ") {
                let ruleName = trimmed.dropFirst("--rules ".count)
                    .trimmingCharacters(in: .whitespaces)
                rules["rule:\(ruleName)"] = "enabled"
            }
            // Parse --disable lines
            else if trimmed.hasPrefix("--disable ") {
                let ruleName = trimmed.dropFirst("--disable ".count)
                    .trimmingCharacters(in: .whitespaces)
                rules["rule:\(ruleName)"] = "disabled"
            }
            // Parse option lines (--optionname value)
            else if trimmed.hasPrefix("--") {
                let parts = trimmed.split(separator: " ", maxSplits: 1)
                if parts.count == 2 {
                    let optionName = String(parts[0].dropFirst(2)) // Remove --
                    let value = String(parts[1])
                    rules["option:\(optionName)"] = value
                } else if parts.count == 1 {
                    // Option without value (like --enable)
                    let optionName = String(parts[0].dropFirst(2))
                    rules["option:\(optionName)"] = "true"
                }
            }
        }

        return rules
    }

    /// Reconstruct SwiftFormat config from rules dictionary
    ///
    /// Preserves comments and structure from base config, applying overrides
    private static func reconstructSwiftFormatConfig(
        _ rules: [String: String],
        baseContent: String,
        overrideContent: String
    ) -> String {
        var result: [String] = []
        var processedRules = Set<String>()

        // Header comment
        result.append("# Merged SwiftFormat configuration")
        result.append("# Base config + project-specific overrides")
        result.append("")

        // Add override content as a comment header
        result.append("# === Project-specific overrides applied ===")
        for line in overrideContent.components(separatedBy: .newlines) {
            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                result.append("# \(line)")
            }
        }
        result.append("# === End overrides ===")
        result.append("")

        // Process base config, applying overrides
        for line in baseContent.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Preserve section comments
            if trimmed.hasPrefix("#") {
                result.append(line)
                continue
            }

            // Preserve empty lines
            if trimmed.isEmpty {
                result.append(line)
                continue
            }

            // Process rule lines
            if trimmed.hasPrefix("--rules ") {
                let ruleName = trimmed.dropFirst("--rules ".count)
                    .trimmingCharacters(in: .whitespaces)
                let ruleKey = "rule:\(ruleName)"
                processedRules.insert(ruleKey)

                if let ruleState = rules[ruleKey] {
                    if ruleState == "enabled" {
                        result.append("--rules \(ruleName)")
                    } else if ruleState == "disabled" {
                        result.append("# --rules \(ruleName) (disabled by override)")
                    }
                } else {
                    result.append(line)
                }
            } else if trimmed.hasPrefix("--disable ") {
                let ruleName = trimmed.dropFirst("--disable ".count)
                    .trimmingCharacters(in: .whitespaces)
                let ruleKey = "rule:\(ruleName)"
                processedRules.insert(ruleKey)

                if let ruleState = rules[ruleKey] {
                    if ruleState == "disabled" {
                        result.append("--disable \(ruleName)")
                    } else if ruleState == "enabled" {
                        result.append("# --disable \(ruleName) (re-enabled by override)")
                    }
                } else {
                    result.append(line)
                }
            } else if trimmed.hasPrefix("--") {
                let parts = trimmed.split(separator: " ", maxSplits: 1)
                if parts.count >= 1 {
                    let optionName = String(parts[0].dropFirst(2))
                    let optionKey = "option:\(optionName)"
                    processedRules.insert(optionKey)

                    if let overrideValue = rules[optionKey] {
                        if parts.count == 2 {
                            result.append("--\(optionName) \(overrideValue)")
                        } else {
                            result.append("--\(optionName)")
                        }
                    } else {
                        result.append(line)
                    }
                }
            } else {
                result.append(line)
            }
        }

        // Add any new rules from overrides that weren't in base config
        let newRules = rules.keys.filter { !processedRules.contains($0) }
        if !newRules.isEmpty {
            result.append("")
            result.append("# === Additional overrides ===")
            for ruleKey in newRules.sorted() {
                let value = rules[ruleKey]!
                if ruleKey.hasPrefix("rule:") {
                    let ruleName = String(ruleKey.dropFirst("rule:".count))
                    if value == "enabled" {
                        result.append("--rules \(ruleName)")
                    } else if value == "disabled" {
                        result.append("--disable \(ruleName)")
                    }
                } else if ruleKey.hasPrefix("option:") {
                    let optionName = String(ruleKey.dropFirst("option:".count))
                    result.append("--\(optionName) \(value)")
                }
            }
        }

        return result.joined(separator: "\n")
    }

    /// Create temporary merged config file
    ///
    /// - Parameters:
    ///   - baseConfig: URL of base configuration file
    ///   - overrides: URL of overrides file
    /// - Returns: URL of temporary merged config file
    /// - Throws: Error if merge or file creation fails
    public static func createMergedConfig(baseConfig: URL, overrides: URL) throws -> URL {
        let mergedContent = try mergeSwiftFormatConfigs(baseConfig: baseConfig, overrides: overrides)

        let tempDir = FileManager.default.temporaryDirectory
        let tempConfig = tempDir.appendingPathComponent("swiftformat-merged-\(UUID().uuidString).yml")

        try mergedContent.write(to: tempConfig, atomically: true, encoding: .utf8)

        return tempConfig
    }
}
