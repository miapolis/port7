import React from "react";
import { GameMilestone, Tile as TileData } from "@port7/dock/lib/games/rumble";
import { useConn } from "@port7/hooks/use-conn";
import { useRumbleStore } from "../../use-rumble-store";
import { Tile } from "./tile";

export const TileContainer: React.FC = () => {
  const conn = useConn();
  const state = useRumbleStore();
  const milestone = state.milestone as GameMilestone;
  const [sendInterval, setSendInterval] = React.useState<
    NodeJS.Timeout | undefined
  >(undefined);

  const [canSend, setCanSend] = React.useState(true);
  const [tiles, setTiles] = React.useState<Map<number, TileData>>(
    milestone.tiles
  );

  const onDrag = (event: any) => {
    const { id, deltaX, deltaY } = event;
    const current = tiles.get(id);

    if (!current) return;
    current.x += deltaX;
    current.y += deltaY;
    setTiles(tiles.set(id, current));
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

  React.useEffect(() => {
    console.log("TILES", tiles);
  }, [tiles]);

  return (
    <div>
      {Array.from(tiles.values()).map((tile) => {
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
