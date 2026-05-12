import Foundation

public struct WorkoutToolRegistry {
    
    private static let stepSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "duration": ["type": "number", "description": "Duration in seconds"],
            "targetPowerPercent": ["type": "number", "description": "Target intensity as decimal % of FTP (e.g. 0.95 for 95%)"],
            "targetHeartRatePercent": ["type": "number", "description": "Target heart rate as decimal % of Max HR (e.g. 0.80 for 80%)"],
            "targetCadence": ["type": "integer", "description": "Target cadence in RPM"],
            "type": [
                "type": "string",
                "enum": ["warmup", "work", "recovery", "cooldown"],
                "description": "The category of the step"
            ]
        ],
        "required": ["duration", "type"]
    ]
    
    private static let stepUpdateSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "duration": ["type": "number", "description": "New duration in seconds"],
            "targetPowerPercent": ["type": "number", "description": "New target intensity as decimal % of FTP"],
            "targetHeartRatePercent": ["type": "number", "description": "New target heart rate as decimal % of Max HR"],
            "targetCadence": ["type": "integer", "description": "New target cadence in RPM"],
            "type": [
                "type": "string",
                "enum": ["warmup", "work", "recovery", "cooldown"],
                "description": "New category of the step"
            ]
        ]
    ]

    public static let tools: [AITool] = [
        AITool(
            name: "reset_workout",
            description: "Replaces the entire current workout with a new set of steps and metadata.",
            parameters: [
                "type": AnyCodable("object"),
                "properties": AnyCodable([
                    "name": ["type": "string", "description": "The name of the workout"],
                    "description": ["type": "string", "description": "A brief description of the workout goals"],
                    "steps": [
                        "type": "array",
                        "items": stepSchema
                    ]
                ]),
                "required": AnyCodable(["name", "description", "steps"])
            ]
        ),
        AITool(
            name: "add_steps",
            description: "Adds one or more workout steps to the end of the current workout.",
            parameters: [
                "type": AnyCodable("object"),
                "properties": AnyCodable([
                    "steps": [
                        "type": "array",
                        "items": stepSchema
                    ]
                ]),
                "required": AnyCodable(["steps"])
            ]
        ),
        AITool(
            name: "update_steps",
            description: "Modifies existing workout steps at the specified indices.",
            parameters: [
                "type": AnyCodable("object"),
                "properties": AnyCodable([
                    "indices": [
                        "type": "array",
                        "items": ["type": "integer"],
                        "description": "The 0-based indices of the steps to update"
                    ],
                    "changes": stepUpdateSchema
                ]),
                "required": AnyCodable(["indices", "changes"])
            ]
        ),
        AITool(
            name: "remove_steps",
            description: "Removes workout steps at the specified indices.",
            parameters: [
                "type": AnyCodable("object"),
                "properties": AnyCodable([
                    "indices": [
                        "type": "array",
                        "items": ["type": "integer"],
                        "description": "The 0-based indices of the steps to remove"
                    ]
                ]),
                "required": AnyCodable(["indices"])
            ]
        ),
        AITool(
            name: "duplicate_block",
            description: "Duplicates a range of workout steps multiple times (e.g. for intervals).",
            parameters: [
                "type": AnyCodable("object"),
                "properties": AnyCodable([
                    "start": ["type": "integer", "description": "The starting index of the block to duplicate"],
                    "end": ["type": "integer", "description": "The ending index (inclusive) of the block to duplicate"],
                    "repeats": ["type": "integer", "description": "How many times to repeat the block (total iterations = repeats + 1)"]
                ]),
                "required": AnyCodable(["start", "end", "repeats"])
            ]
        ),
        AITool(
            name: "set_metadata",
            description: "Updates the workout name and/or description.",
            parameters: [
                "type": AnyCodable("object"),
                "properties": AnyCodable([
                    "name": ["type": "string", "description": "The new name of the workout"],
                    "description": ["type": "string", "description": "The new description of the workout"]
                ])
            ]
        )
    ]
}
