class_name Net
extends RefCounted
## Thin helpers around ENet for co-op: open a room, join one by address, leave. The host is the
## server and simulates everything; see match/net_sync.gd for what travels over the wire.
## Works on any MultiplayerAPI so tests can run a host and a client in one process.

const PORT := 24690
const MAX_PLAYERS := 5


## Opens a room on this machine. Returns OK or the ENet error.
static func host(api: MultiplayerAPI, port: int = PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_PLAYERS - 1)
	if error == OK:
		api.multiplayer_peer = peer
	return error


## Starts connecting to a room; `connected_to_server` / `connection_failed` tell how it went.
static func join(api: MultiplayerAPI, address: String, port: int = PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error == OK:
		api.multiplayer_peer = peer
	return error


static func leave(api: MultiplayerAPI) -> void:
	if is_online(api):
		api.multiplayer_peer.close()
	api.multiplayer_peer = OfflineMultiplayerPeer.new()


static func is_online(api: MultiplayerAPI) -> bool:
	return api.has_multiplayer_peer() and not api.multiplayer_peer is OfflineMultiplayerPeer \
		and api.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED


## This machine's IPv4 LAN addresses, to tell friends where to join.
static func lan_addresses() -> PackedStringArray:
	var found := PackedStringArray()
	for address in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127.") and not address.begins_with("169.254."):
			found.append(address)
	return found
