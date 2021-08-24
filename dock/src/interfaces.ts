export type GameType = "rumble";

export type AuthMethod = "port7";

export type Role = "leader";

export type RoomCreateResponse = {
  data: Room | null,
  errors: string[] | undefined,
}

export type Room = {
  id: string,
  name: string,
  code: string,
  isPrivate: string,
  game: GameType,
}

export type Peer = {
  id: number;
  nickname: string;
  isDisconnected: boolean;
}

export type ManagedPeer = {
  id: number;
  nickname: string;
  authMethod: AuthMethod;
  authUsername: string;
  roles: Role[];
}
