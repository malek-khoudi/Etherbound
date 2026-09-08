## The six natural affinities.
##
## Canon: an Etherbound has ONE affinity. Progression never buys another.
## See docs/CANON.md and AGENTS.md section 3 rule 7.
class_name Affinity
extends RefCounted

enum Kind {
	KINETIC,
	GRAVITIC,
	THERMIC,
	TRANSMUTATIVE,
	VITAL,
	RADIANT,
}

const DISPLAY_NAMES: Dictionary = {
	Kind.KINETIC: "Kinetic",
	Kind.GRAVITIC: "Gravitic",
	Kind.THERMIC: "Thermic",
	Kind.TRANSMUTATIVE: "Transmutative",
	Kind.VITAL: "Vital",
	Kind.RADIANT: "Radiant",
}

## The physical constraint each affinity must obey. Player-facing failure text
## is derived from these, never from a generic "not enough power" message.
const CONSTRAINTS: Dictionary = {
	Kind.KINETIC: "requires an anchor that can carry the reaction",
	Kind.GRAVITIC: "alters acceleration, not weight",
	Kind.THERMIC: "requires a sink to move heat into",
	Kind.TRANSMUTATIVE: "requires a maintained front on contiguous material",
	Kind.VITAL: "repairs organisation, which is not recovery",
	Kind.RADIANT: "requires line of sight, aim and dwell time",
}

static func display_name(kind: Kind) -> String:
	return DISPLAY_NAMES.get(kind, "Unknown")

static func constraint(kind: Kind) -> String:
	return CONSTRAINTS.get(kind, "")
