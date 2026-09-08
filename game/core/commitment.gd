## One sustained task an Etherbound is holding.
##
## A commitment is not a cast-and-forget spell. It occupies junctions and draws
## throughput for as long as it is held. Holding a beam IS a commitment.
class_name Commitment
extends RefCounted

var id: StringName
## Player-facing. Shown in the commitment list. Must read as a physical act.
var label: String
## Throughput this task wants, per second. Not a damage number.
var demand: float
## How many of the six junctions this occupies.
var junctions: int
## Throughput actually allocated. Falls below demand when the body is oversubscribed.
var granted: float = 0.0

func _init(p_id: StringName, p_label: String, p_demand: float, p_junctions: int = 1) -> void:
	id = p_id
	label = p_label
	demand = maxf(p_demand, 0.0)
	junctions = maxi(p_junctions, 1)

## 1.0 means the task is fully served. Below 1.0 the beam is slipping.
func service_ratio() -> float:
	if demand <= 0.0:
		return 1.0
	return granted / demand
