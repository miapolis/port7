import React from "react";
import { DraggableCore, DraggableData, DraggableEvent } from "react-draggable";
import { Tile as TileData } from "@port7/dock/lib/games/rumble";

export interface TileProps {
  id: number;
  data: TileData;
  onDrag: (event: any) => void;
  onDragStop: (id: number) => void;
}

export const Tile: React.FC<TileProps> = ({ id, data, onDrag, onDragStop }) => {
  const onDragThis = (e: DraggableEvent, data: DraggableData) => {
    onDrag({ id: id, deltaX: data.deltaX, deltaY: data.deltaY });
  };

  return (
    <DraggableCore onDrag={onDragThis} onStop={() => onDragStop(id)}>
      <div
        className="rounded-lg bg-primary-600"
        style={{
          width: "100px",
          height: "130px",
          transform: `translate(${data.x}px, ${data.y}px)`,
        }}
      ></div>
    </DraggableCore>
  );
};
