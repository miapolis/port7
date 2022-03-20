import React from "react";
import {
  GameMilestone,
  Tile as TileData,
  TileObject,
} from "@port7/dock/lib/games/rumble";
import { State as ContainerState } from "./math/container";
import { useConn } from "@port7/hooks/use-conn";
import { useRumbleStore } from "../../use-rumble-store";
import { Tile } from "./tile";
import { GroupHandle } from "./group-handle";
import { canSnap } from "../../util/tiles";

export const AREA_WIDTH = 4000;
export const AREA_HEIGHT = 4000;
const TILE_WIDTH = 100;
const TILE_HEIGHT = 130;
const SNAP_NEAR = 60;
const SNAP_NEAR_Y = 120;
export const SNAP_END_DELAY_MS = 100;

export interface TileContainerProps {
  onUpdateMatrixScale: (scale: number) => void;
}

export const TileContainer: React.FC<TileContainerProps> = ({
  onUpdateMatrixScale,
}) => {
  const conn = useConn();
  const state = useRumbleStore();
  const updateTile = state.updateTile;
  const milestone = state.milestone as GameMilestone;
  const tiles = milestone.tiles;
  const [sendInterval, setSendInterval] = React.useState<
    NodeJS.Timeout | undefined
  >(undefined);

  const outerRef = React.useRef<HTMLDivElement>(null);
  const containerRef = React.useRef<HTMLDivElement>(null);
  const [containerMouseDown, setContainerMouseDown] =
    React.useState<boolean>(false);
  const [containerState, setContainerState] = React.useState<ContainerState>(
    new ContainerState(0.5, 2, 12)
  );

  const [canSend, setCanSend] = React.useState(true);
  const [handle, setHandle] = React.useState<
    | {
        show: boolean;
        tileId: number;
        groupId: number;
        offsetRight: boolean;
        pos: { x: number; y: number };
      }
    | undefined
  >();
  const [handleDragging, setHandleDragging] = React.useState(false);

  React.useEffect(() => {
    setHandle(undefined);
  }, [milestone.isAnyServerMoving]);

  const findSnappable = (allTiles: TileObject[], current: TileObject) => {
    const result: TileObject[] = [];
    const milestone = useRumbleStore.getState().milestone as GameMilestone;

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
        if (canSnap(milestone, current, tile, snapSide))
          result.push({ ...tile, snapSide });
      } else if (tile.snapSide !== undefined) {
        // Snap side undefined signifies unsnapping the tile
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
    setHandle(undefined);

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

  const trySend = (data: any, force = false, group = false) => {
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
      setCanSend(false);
      conn?.sendCast(`rumble:${group ? "move_group" : "move_tile"}`, {
        id: data.id,
        x,
        y,
        endMove: force ?? null,
      });
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
    if (handleDragging) return;
    if (!hover) {
      setHandle(undefined);
      return;
    }

    const milestone = useRumbleStore.getState().milestone as GameMilestone;
    const group = milestone.groups.get(tile.groupId);
    if (!group) return;

    const tiles = milestone.tiles;
    const len = group.children.length;
    if (len % 2 == 0) {
      const middleTile = tiles.get(group.children[len / 2 - 1])!;
      setHandle({
        show: true,
        tileId: middleTile.id,
        groupId: tile.groupId,
        offsetRight: true,
        pos: { x: middleTile.x + TILE_WIDTH, y: middleTile.y + TILE_HEIGHT },
      });
    } else {
      const middleTile = tiles.get(group.children[(len + 1) / 2 - 1])!;
      setHandle({
        show: true,
        tileId: middleTile.id,
        groupId: tile.groupId,
        offsetRight: false,
        pos: {
          x: middleTile.x + TILE_WIDTH / 2,
          y: middleTile.y + TILE_HEIGHT,
        },
      });
    }
  };

  const onHandleDrag = (deltaX: number, deltaY: number, force = false) => {
    setHandleDragging(!force);

    const newX = handle!.pos.x + deltaX;
    const newY = handle!.pos.y + deltaY;

    setHandle({
      ...handle!,
      pos: { x: newX, y: newY },
    });

    const milestone = useRumbleStore.getState().milestone as GameMilestone;
    const tiles = milestone.tiles;
    const group = milestone.groups.get(handle!.groupId)!;

    group.children.forEach((id) => {
      const tile = tiles.get(id)!;
      tile.x += deltaX;
      tile.y += deltaY;
      // If force is true, it signifies an end move
      tile.isDragging = !force;

      updateTile(tile);
    });

    trySend({ id: group.id, x: newX, y: newY }, force, true);
  };

  return (
    <div ref={outerRef} className="absolute w-full h-full bg-primary-800">
      <div
        ref={containerRef}
        className="absolute const-tile-container bg-primary-900"
        style={{
          width: AREA_WIDTH,
          height: AREA_HEIGHT,
          transform: containerState.elementTransform,
          transformOrigin: containerState.elementTransformOrigin,
        }}
        onWheel={(e) => {
          const { left, top } = containerRef.current?.getBoundingClientRect()!;

          const [transform, transformOrigin, scale] = containerState.zoom(
            e.pageX,
            e.pageY,
            Math.sign(e.deltaY) > 0 ? -1 : 1,
            left,
            top
          );

          onUpdateMatrixScale(scale as number);
          setContainerState({
            ...containerState,
            elementTransform: transform as string,
            elementTransformOrigin: transformOrigin as string,
            transform: { ...containerState.transform, scale: scale as number },
          });
        }}
        onDoubleClick={() => {
          let width = outerRef.current?.clientWidth!;
          let height = outerRef.current?.clientHeight!;

          const elementTransform = containerState.panTo(
            -2000 + width / 2,
            -2000 + height / 2,
            1
          );

          onUpdateMatrixScale(1);
          setContainerState({
            ...containerState,
            elementTransform: elementTransform,
            transform: { ...containerState.transform, scale: 1 },
          });
        }}
        onMouseMove={(e) => {
          if (!containerMouseDown) {
            return;
          }
          e.preventDefault();

          const elementTransform = containerState.pan(e.movementX, e.movementY);
          setContainerState({
            ...containerState,
            elementTransform: elementTransform,
          });
        }}
        onMouseDown={(e) => {
          const classes = (e.target as HTMLDivElement).className;
          if (classes.includes("const-tile-container")) {
            setContainerMouseDown(true);
          }
        }}
        onMouseUp={() => setContainerMouseDown(false)}
      >
        <div className="absolute">
          {Array.from(tiles.values()).map((tile) => {
            return (
              <Tile
                key={tile.id}
                id={tile.id}
                data={tile}
                scale={containerState.transform.scale}
                onDrag={onDrag}
                onDragStop={onDragStop}
                onHover={(hover) => onTileHover(tile, hover)}
              />
            );
          })}
          <GroupHandle
            show={handle?.show!}
            pos={handle?.pos!}
            scale={containerState.transform.scale}
            onDrag={onHandleDrag}
            onDragStop={() => {
              onHandleDrag(0, 0, true);
            }}
            onHover={(hover: boolean) =>
              setHandle({ ...handle!, show: handleDragging || hover })
            }
          />
        </div>
      </div>
    </div>
  );
};
