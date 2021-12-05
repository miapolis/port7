import { GameMilestone, Group, TileObject } from "@port7/dock/lib/games/rumble";

export const canSnap = (
  milestone: GameMilestone,
  main: TileObject,
  target: TileObject,
  snapSide: 0 | 1
): boolean => {
  const tiles = milestone.tiles;
  const groups = milestone.groups;

  if (target.groupId != null) {
    // A group exists for the target tile, we must follow the rules
    // of the group in order to snap to it
    const group = groups.get(target.groupId)!;

    if (group.groupType == "set") {
      return canSnapSet(tiles, group, main, target);
    } else {
      // A run (main is snapping to target at snapSide)
      return canSnapRun(main, target, snapSide);
    }
  } else {
    return canSnapNew(main, target);
  }
};

const canSnapSet = (
  tiles: Map<number, TileObject>,
  group: Group,
  main: TileObject,
  target: TileObject
): boolean => {
  if (group.children.length == 4) return false;

  // In order to snap to a set, the value must be the same
  if (main.data.value != target.data.value) return false;
  // The color must also be different
  const colors = new Array<number>();

  group.children.forEach((id) => {
    const tile = tiles.get(id)!;
    colors.push(tile.data.color);
  });

  if (colors.includes(main.data.color)) return false;

  return true;
};

const canSnapRun = (
  main: TileObject,
  target: TileObject,
  snapSide: 0 | 1
): boolean => {
  if (main.data.color != target.data.color) return false;

  if (snapSide == 0) {
    // One less
    return main.data.value == target.data.value - 1;
  } else {
    return main.data.value == target.data.value + 1;
  }
};

const canSnapNew = (main: TileObject, target: TileObject): boolean => {
  if (main.data.color == target.data.color) {
    return Math.abs(main.data.value - target.data.value) == 1;
  } else {
    return main.data.value == target.data.value;
  }
};
