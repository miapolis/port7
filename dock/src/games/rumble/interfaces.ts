export interface Peer {
  id: number;
  nickname: string;
  isDisconnected: boolean;
}

export type GroupType = "set" | "run";

export interface Group {
  id: number;
  children: number[];
  groupType: GroupType;
}

export interface TileData {
  value: number;
  color: number;
}

export interface Tile {
  id: number;
  x: number;
  y: number;
  groupId: number | undefined;
  data: TileData;
}

export interface TileObject extends Tile {
  lockedX: number | undefined;
  lockedY: number | undefined;
  snapSide: 0 | 1 | undefined;
  isDragging: boolean;
  isSnapping: boolean;
  isServerMoving: boolean;
}

export interface BaseMilestone {
  state: string;
}

export interface LobbyMilestone extends BaseMilestone {
  startTime: number | undefined;
}

export interface GameMilestone extends BaseMilestone {
  currentTurn: number;
  tiles: Map<number, TileObject>;
  groups: Map<number, Group>;
  isAnyServerMoving: boolean;
}

export type Milestone = LobbyMilestone | GameMilestone;
