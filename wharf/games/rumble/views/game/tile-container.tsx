import React from "react";
import { GameMilestone, Tile as TileData } from "@port7/dock/lib/games/rumble";
import { useConn } from "@port7/hooks/use-conn";
import { useRumbleStore } from "../../use-rumble-store";
import { Tile } from "./tile";

const TILE_WIDTH = 100;
const TILE_HEIGHT = 130;
const SNAP_NEAR = 12;
const SNAP_INDICATOR_NEAR = 60;
const SNAP_INDICATOR_NEAR_Y = 120;
export const SNAP_END_DELAY_MS = 50;

export interface TileObject {
  id: number;
  x: number;
  y: number;
  lockedX: number | undefined;
  lockedY: number | undefined;
  highlightRight: boolean | undefined;
  isSnapping: boolean;
}

export const TileContainer: React.FC = () => {
  const conn = useConn();
  const state = useRumbleStore();
  const milestone = state.milestone as GameMilestone;
  const [sendInterval, setSendInterval] = React.useState<
    NodeJS.Timeout | undefined
  >(undefined);

  const [canSend, setCanSend] = React.useState(true);
  const [tiles, setTiles] = React.useState<Map<number, TileObject>>(
    new Map(
      Array.from(milestone.tiles.values()).map((t) => [
        t.id,
        {
          ...t,
          highlightRight: undefined,
          isSnapping: false,
          lockedX: undefined,
          lockedY: undefined,
        },
      ])
    )
  );

  const findSnappable = (allTiles: TileObject[], current: TileObject) => {
    const snappable = new Array<{
      tile: TileObject;
      snapRight: boolean;
      snap: boolean;
    }>();
    allTiles.forEach((tile) => {
      let xSnapRight = false,
        xSnapLeft = false;
      let doSnap = false;
      // Determine if the distance is close enough
      const rightOfTile = tile.x + TILE_WIDTH / 2;
      const leftOfCurrent = current.x - TILE_WIDTH / 2;

      if (Math.abs(rightOfTile - leftOfCurrent) < SNAP_INDICATOR_NEAR) {
        xSnapRight = true;
        if (Math.abs(rightOfTile - leftOfCurrent) < SNAP_NEAR) {
          doSnap = true;
        }
      } else {
        const leftOfTile = tile.x - TILE_WIDTH / 2;
        const rightOfCurrent = current.x + TILE_WIDTH / 2;
        if (Math.abs(leftOfTile - rightOfCurrent) < SNAP_INDICATOR_NEAR) {
          xSnapLeft = true;
          if (Math.abs(leftOfTile - rightOfCurrent) < SNAP_NEAR) {
            doSnap = true;
          }
        }
      }

      if (
        (xSnapRight || xSnapLeft) &&
        Math.abs(tile.y - current.y) < SNAP_INDICATOR_NEAR_Y
      ) {
        snappable.push({
          tile: { ...tile, highlightRight: xSnapRight },
          snapRight: xSnapRight,
          snap: doSnap,
        });
      } else if (tile.highlightRight !== undefined) {
        snappable.push({
          tile: { ...tile, highlightRight: undefined },
          snapRight: xSnapRight,
          snap: false,
        });
      }
    });
    return snappable;
  };

  React.useEffect(() => {
    setTiles(
      new Map(
        Array.from(milestone.tiles.values()).map((t) => [
          t.id,
          {
            ...t,
            highlightRight: undefined,
            isSnapping: false,
            lockedX: undefined,
            lockedY: undefined,
          },
        ])
      )
    );
  }, [milestone]);

  const onDrag = (event: any) => {
    const { id, deltaX, deltaY } = event;
    const current = tiles.get(id);

    if (!current) return;
    // Find available tiles for snapping
    const snappable = findSnappable(Array.from(tiles.values()), current);

    if (snappable.length === 0) {
      current.x += deltaX;
      current.y += deltaY;
    } else {
      // Set x and y to match
      const tile = snappable[0];
      if (tile.snapRight) {
        if (tile.snap) current.lockedX = tile.tile.x + TILE_WIDTH;
        else current.lockedX = undefined;
      } else {
        if (tile.snap) current.lockedX = tile.tile.x - TILE_WIDTH;
        else current.lockedX = undefined;
      }

      if (tile.snap) {
        current.lockedY = tile.tile.y;
        tile.tile.highlightRight = undefined;
      } else {
        current.lockedY = undefined;
      }

      current.x += deltaX;
      current.y += deltaY;
      setTiles(tiles.set(tile.tile.id, tile.tile).set(id, current));
    }

    setTiles(tiles.set(id, current));
    trySend(current);
  };

  const onDragStop = (id: number) => {
    const current = tiles.get(id);
    if (!current) return;
    const snappable = findSnappable(Array.from(tiles.values()), current);

    if (snappable.length !== 0) {
      const tile = snappable[0];
      // Snap to highlighted tiles
      if (tile.tile.highlightRight !== undefined) {
        current.isSnapping = true;
        tile.tile.highlightRight = undefined;

        setTiles(tiles.set(id, current).set(tile.tile.id, tile.tile));

        if (tile.snapRight) {
          current.lockedX = tile.tile.x + TILE_WIDTH;
        } else {
          current.lockedX = tile.tile.x - TILE_WIDTH;
        }
        current.lockedY = tile.tile.y;

        setTiles(tiles.set(id, current));
        trySend(current);

        const currentClone = current;
        setTimeout(() => {
          currentClone.isSnapping = false;
          setTiles(tiles.set(id, currentClone));
        }, SNAP_END_DELAY_MS);
      }
    }

    clearLock(current);
    setTiles(tiles.set(id, current));
    useRumbleStore.getState().updateTile(current as TileData);
  };

  const clearLock = (tile: TileObject) => {
    if (tile.lockedX) tile.x = tile.lockedX;
    if (tile.lockedY) tile.y = tile.lockedY;
    tile.isSnapping = false;
    tile.lockedX = undefined;
    tile.lockedY = undefined;
  };

  const trySend = (data: any) => {
    if (!sendInterval) {
      setSendInterval(
        setInterval(() => {
          setCanSend(true);
        }, 20)
      );
    }

    const x = data.lockedX ?? data.x;
    const y = data.lockedY ?? data.y;
    if (canSend) {
      conn?.sendCast("rumble:move_tile", { id: data.id, x, y });
      setCanSend(false);
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
            onDrag={onDrag}
            onDragStop={onDragStop}
          />
        );
      })}
    </div>
  );
};
