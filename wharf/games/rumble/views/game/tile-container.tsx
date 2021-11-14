import React from "react";
import {
  GameMilestone,
  Tile as TileData,
  TileObject,
} from "@port7/dock/lib/games/rumble";
import { useConn } from "@port7/hooks/use-conn";
import { useRumbleStore } from "../../use-rumble-store";
import { Tile } from "./tile";

const TILE_WIDTH = 100;
const SNAP_NEAR = 60;
const SNAP_NEAR_Y = 120;
export const SNAP_END_DELAY_MS = 100;

export const TileContainer: React.FC = () => {
  const conn = useConn();
  const state = useRumbleStore();
  const updateTile = state.updateTile;
  const milestone = state.milestone as GameMilestone;
  const tiles = milestone.tiles;
  const [sendInterval, setSendInterval] = React.useState<
    NodeJS.Timeout | undefined
  >(undefined);

  const [canSend, setCanSend] = React.useState(true);
  const [currentHandle, setCurrentHandle] = React.useState<
    { tileId: number; offset: boolean } | undefined
  >();

  const findSnappable = (allTiles: TileObject[], current: TileObject) => {
    const result: TileObject[] = [];

    Array.from(allTiles).forEach((tile) => {
      let snapSide: 0 | 1 | undefined = undefined;
      const rightOfTile = tile.x + TILE_WIDTH / 2;
      const leftOfCurrent = current.x - TILE_WIDTH / 2;

      if (Math.abs(rightOfTile - leftOfCurrent) < SNAP_NEAR) {
        snapSide = 1;
      } else {
        const leftOfTile = tile.x - TILE_WIDTH / 2;
        const rightOfCurrent = current.x + TILE_WIDTH / 2;

        if (Math.abs(leftOfTile - rightOfCurrent) < SNAP_NEAR) {
          snapSide = 0;
        }
      }

      if (
        snapSide !== undefined &&
        Math.abs(tile.y - current.y) < SNAP_NEAR_Y
      ) {
        result.push({ ...tile, snapSide });
      } else if (tile.snapSide !== undefined) {
        result.push({ ...tile, snapSide: undefined });
      }
    });

    return result;
  };

  const onDrag = (event: any) => {
    const { id, deltaX, deltaY } = event;
    const current = tiles.get(id);

    if (!current) return;

    const snappable = findSnappable(Array.from(tiles.values()), current);
    setCurrentHandle(undefined);

    current.isDragging = true;
    current.x += deltaX;
    current.y += deltaY;

    snappable.forEach((tile) => {
      updateTile(tile);
    });
    updateTile(current);

    trySend(current);
  };

  const onDragStop = (id: number) => {
    const current = tiles.get(id);
    if (!current) return;
    const snappable = findSnappable(Array.from(tiles.values()), current);

    if (snappable.length !== 0) {
      if (current.groupId != null) return;

      // Determine which tile we are actually going to snapping to
      let tile;
      if (snappable.length === 1) tile = snappable[0];
      else {
        tile = closestToCurrent(snappable, current);
      }

      if (tile.snapSide !== undefined) {
        const snapSide = tile.snapSide;
        current.isSnapping = true;

        if (snapSide === 1) {
          current.lockedX = tile.x + TILE_WIDTH;
        } else {
          current.lockedX = tile.x - TILE_WIDTH;
        }
        current.lockedY = tile.y;

        updateTile(current);
        snappable.forEach((s) => {
          s.snapSide = undefined;
          updateTile(s);
        });

        sendSnap(current, tile.id, snapSide);

        setTimeout(() => {
          current.isSnapping = false;
          updateTile(current);
        }, SNAP_END_DELAY_MS);
      }
    } else {
      // Force the sending of the final move
      trySend(current, true);
    }

    clearLock(current);
    updateTile(current);
  };

  const closestToCurrent = (tiles: TileObject[], current: TileObject) => {
    let closestData: { diffX: number; diffY: number; id: number } | undefined =
      undefined;

    tiles.forEach((tile) => {
      const diffLeftToRight = Math.abs(
        tile.x + TILE_WIDTH / 2 - (current.x - TILE_WIDTH / 2)
      );
      const diffRightToLeft = Math.abs(
        tile.x - TILE_WIDTH / 2 - (current.x + TILE_WIDTH / 2)
      );
      const diffX = Math.min(diffLeftToRight, diffRightToLeft);
      const diffY = Math.abs(tile.y - current.y);

      if (!closestData) {
        closestData = { diffX, diffY, id: tile.id };
        return;
      } else if (
        diffX < closestData.diffX ||
        (diffX === closestData.diffX && diffY < closestData.diffY)
      ) {
        closestData = { diffX, diffY, id: tile.id };
      }
    });

    return tiles.find((x) => x.id === closestData?.id) as TileObject;
  };

  const clearLock = (tile: TileObject) => {
    if (tile.lockedX) tile.x = tile.lockedX;
    if (tile.lockedY) tile.y = tile.lockedY;
    tile.lockedX = undefined;
    tile.lockedY = undefined;
    tile.isDragging = false;
  };

  const trySend = (data: any, force = false) => {
    if (!sendInterval) {
      setSendInterval(
        setInterval(() => {
          setCanSend(true);
        }, 20)
      );
    }

    const x = data.lockedX ?? data.x;
    const y = data.lockedY ?? data.y;
    if (canSend || force) {
      conn?.sendCast("rumble:move_tile", {
        id: data.id,
        x,
        y,
        endMove: force ?? null,
      });
      setCanSend(false);
    }
  };

  const sendSnap = (tile: TileObject, snapId: number, snapSide: number) => {
    conn?.sendCast("rumble:move_tile", {
      id: tile.id,
      x: tile.x,
      y: tile.y,
      snapTo: snapId,
      snapSide,
    });
  };

  const onTileHover = (tile: TileObject, hover: boolean) => {
    if (tile.groupId == null) return;
    if (!hover) {
      setCurrentHandle(undefined);
      return;
    }

    const milestone = useRumbleStore.getState().milestone as GameMilestone;
    const group = milestone.groups.get(tile.groupId)!;

    const len = group.children.length;
    if (len % 2 == 0) {
      setCurrentHandle({ tileId: group.children[len / 2 - 1], offset: true });
    } else {
      setCurrentHandle({
        tileId: group.children[(len + 1) / 2 - 1],
        offset: false,
      });
    }
  };

  return (
    <div>
      {Array.from(tiles.values()).map((tile) => {
        return (
          <Tile
            key={tile.id}
            id={tile.id}
            data={tile}
            showHandle={{
              show: currentHandle?.tileId == tile.id,
              offset: currentHandle?.offset || false,
            }}
            onDrag={onDrag}
            onDragStop={onDragStop}
            onHover={(hover) => onTileHover(tile, hover)}
          />
        );
      })}
    </div>
  );
};
