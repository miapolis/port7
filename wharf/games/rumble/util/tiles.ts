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
      // A run
      // if ()
    }
  } else {
    // return false;
  }

  return true;
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
  tiles: Map<number, TileObject>,
  group: Group,
  main: TileObject,
  target: TileObject
): boolean => {
  return true;
};
