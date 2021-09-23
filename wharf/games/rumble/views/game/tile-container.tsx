import { useConn } from "@port7/hooks/use-conn";
import { Queue } from "@port7/lib/queue";
import React from "react";
import { Tile } from "./tile";

export interface TileData {
  id: number;
  x: number;
  y: number;
}

export const TileContainer: React.FC = () => {
  const conn = useConn();
  const [sendInterval, setSendInterval] = React.useState<
    NodeJS.Timeout | undefined
  >(undefined);
  // const [sendItem, setSendItem] = React.useState<TileData | undefined>();

  const [canSend, setCanSend] = React.useState(true);
  const [tiles, setTiles] = React.useState<TileData[]>([
    { id: 0, x: 0, y: 0 },
    { id: 1, x: 300, y: 300 },
    { id: 2, x: 500, y: 500 },
  ]);
  const onDrag = (event: any) => {
    const { id, deltaX, deltaY } = event;
    const current = tiles.find((t) => t.id === id) as TileData;
    current.x += deltaX;
    current.y += deltaY;
    setTiles([...tiles]);
    trySend(current);
  };

  const trySend = (data: any) => {
    if (!sendInterval) {
      setSendInterval(
        setInterval(() => {
          setCanSend(true);
        }, 20)
      );
    }

    if (canSend) {
      conn?.sendCast("rumble:move_tile", data);
      setCanSend(false);
    }
  };

  return (
    <div>
      {tiles.map((tile) => {
        return (
          <Tile
            key={tile.id}
            id={tile.id}
            data={tile}
            onDrag={onDrag}
            onDragStop={(id: number) => {}}
          />
        );
      })}
    </div>
  );
};
