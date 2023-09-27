import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
export interface Asset {
	id: string;
	url: string;
	created: bigint;
	content: [] | [Array<Uint8Array | number[]>];
	owner: string;
	chunks_size: bigint;
	canister_id: string;
	content_size: bigint;
	content_type: string;
	filename: string;
	content_encoding: ContentEncoding;
}
export interface AssetProperties {
	content_type: string;
	filename: string;
	checksum: bigint;
	content_encoding: ContentEncoding;
}
export type Asset_ID = string;
export type ContentEncoding = { GZIP: null } | { Identity: null };
export type ErrCommitBatch =
	| { ChecksumInvalid: boolean }
	| { ChunkNotFound: boolean }
	| { ChunkOwnerInvalid: boolean };
export type ErrDeleteAsset = { AssetNotFound: boolean } | { NotAuthorized: boolean };
export interface FileStorage {
	chunks_size: ActorMethod<[], bigint>;
	commit_batch: ActorMethod<[Array<bigint>, AssetProperties], Result_2>;
	create_chunk: ActorMethod<[Uint8Array | number[], bigint], bigint>;
	delete_asset: ActorMethod<[Asset_ID], Result_1>;
	get: ActorMethod<[Asset_ID], Result>;
	get_all_assets: ActorMethod<[], Array<Asset>>;
	get_health: ActorMethod<[], Health>;
	http_request: ActorMethod<[HttpRequest], HttpResponse>;
	http_request_streaming_callback: ActorMethod<
		[StreamingCallbackToken],
		StreamingCallbackHttpResponse
	>;
	is_full: ActorMethod<[], boolean>;
	version: ActorMethod<[], bigint>;
}
export type HeaderField = [string, string];
export interface Health {
	assets_size: bigint;
	heap_mb: bigint;
	memory_mb: bigint;
	cycles: bigint;
}
export interface HttpRequest {
	url: string;
	method: string;
	body: Uint8Array | number[];
	headers: Array<HeaderField>;
}
export interface HttpResponse {
	body: Uint8Array | number[];
	headers: Array<HeaderField>;
	streaming_strategy: [] | [StreamingStrategy];
	status_code: number;
}
export type Result = { ok: Asset } | { err: string };
export type Result_1 = { ok: string } | { err: ErrDeleteAsset };
export type Result_2 = { ok: Asset_ID } | { err: ErrCommitBatch };
export interface StreamingCallbackHttpResponse {
	token: [] | [StreamingCallbackToken];
	body: Uint8Array | number[];
}
export interface StreamingCallbackToken {
	chunk_index: bigint;
	asset_id: string;
	content_encoding: string;
}
export type StreamingStrategy = {
	Callback: {
		token: StreamingCallbackToken;
		callback: [Principal, string];
	};
};
export interface _SERVICE extends FileStorage {}
