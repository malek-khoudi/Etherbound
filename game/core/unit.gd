## Anything that can act in incident mode.
##
## An ordinary person is a Unit with no Etherbound component. That is not a
## lesser Unit. Ordinary units are never throughput-limited, which makes them
## the only thing able to act when the party is at capacity. This is a design
## decision, not an oversight. See AGENTS.md section 1 and section 3 rule 8.
class_name Unit
extends RefCounted

var display_name: String = ""
## null means an ordinary person.
var etherbound: Etherbound = null
var directable: bool = false

func _init(p_name: String, p_etherbound: Etherbound = null) -> void:
	display_name = p_name
	etherbound = p_etherbound

func is_etherbound() -> bool:
	return etherbound != null

## Ordinary people can always act. That is the point of them.
func can_act() -> bool:
	if etherbound == null:
		return true
	return etherbound.has_headroom()

func status_line() -> String:
	if etherbound == null:
		return "%s (ordinary)" % display_name
	return "%s (%s) reserve %.0f/%.0f  throughput %.1f/%.1f  junctions %d/%d" % [
		display_name,
		Affinity.display_name(etherbound.affinity),
		etherbound.reserve, etherbound.reserve_max,
		etherbound.throughput_used(), etherbound.throughput_max,
		etherbound.junctions_used(), Etherbound.JUNCTION_COUNT,
	]
