import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface CanisterInfo {
	id: string;
	created: bigint;
	name: string;
	parent_name: string;
	health: [] | [Health];
}
export interface FileScalingManager {
	get_canister_records: ActorMethod<[], Array<CanisterInfo>>;
	get_current_canister: ActorMethod<[], [] | [CanisterInfo]>;
	get_file_storage_canister_id: ActorMethod<[], string>;
	init: ActorMethod<[], string>;
	version: ActorMethod<[], bigint>;
}
export interface Health {
	assets_size: bigint;
	heap_mb: bigint;
	memory_mb: bigint;
	cycles: bigint;
}
export interface _SERVICE extends FileScalingManager {}
