import React from "react";
import { useRumbleStore } from "@port7/games/rumble/use-rumble-store";
import { GameMilestone } from "@port7/../dock/lib/games/rumble";

export const TileGui: React.FC = () => {
  const milestone = useRumbleStore().milestone as GameMilestone;
  const groups = milestone.groups;
  const tiles = milestone.tiles;
  const [tilesList, setTilesList] = React.useState<string[]>([]);
  const [groupsList, setGroupsList] = React.useState<string[]>([]);

  React.useEffect(() => {
    setInterval(() => {
      setTilesList(calculateTilesList());
      setGroupsList(calculateGroupsList());
    }, 200);
  }, []);

  const calculateTilesList = () => {
    let main = new Array<string>();
    for (const tile of tiles.values()) {
      main.push(
        `[ID: ${tile.id} | group: ${tile.groupId} ${
          tile.isSnapping
            ? "-> snapping "
            : tile.isDragging
            ? "--> dragging "
            : tile.isServerMoving
            ? "--> SERVER MOVING"
            : ""
        }]`
      );
    }

    return main;
  };

  const calculateGroupsList = () => {
    let main = new Array<string>();
    for (const group of groups.values()) {
      main.push(`GROUP ${group.id} | children: [${group.children}]`);
    }

    return main;
  };

  return (
    <div
      className="w-96 h-96 absolute top-24 right-10 p-3 pointer-events-none z-20"
      style={{ background: `rgba(0, 0, 0, 0.2)` }}
    >
      {tilesList.map((item) => {
        return <div className="text-primary-100">{`${item}`}</div>;
      })}
      <div className="h-8"></div>
      {groupsList.map((item) => {
        return <div className="text-primary-100">{`${item}`}</div>;
      })}
    </div>
  );
};
