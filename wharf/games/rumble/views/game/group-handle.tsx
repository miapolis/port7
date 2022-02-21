import React from "react";
import { AREA_WIDTH, AREA_HEIGHT } from "./tile-container";
import { DraggableCore } from "react-draggable";

export interface GroupHandleProps {
  show: boolean;
  pos: { x: number; y: number };
  scale: number;
  onDrag: (deltaX: number, deltaY: number) => void;
  onDragStop: () => void;
  onHover: (hovering: boolean) => void;
}

const WIDTH = 40;
const HEIGHT = 40;

export const GroupHandle = ({
  show,
  pos,
  scale,
  onDrag,
  onDragStop,
  onHover,
}: GroupHandleProps) => {
  return (
    <>
      {show ? (
        <DraggableCore
          onDrag={(_e, data) => {
            onDrag(
              Math.round(data.deltaX / scale),
              Math.round(data.deltaY / scale)
            );
          }}
          onStop={() => onDragStop()}
        >
          <div
            style={{
              width: WIDTH / scale,
              height: HEIGHT / scale,
              cursor: "move",
              position: "absolute",
              transform: `translate(${
                pos.x - WIDTH / scale / 2 + AREA_WIDTH / 2
              }px, ${pos.y - HEIGHT / scale / 2 + AREA_HEIGHT / 2}px)`,
              marginLeft: "auto",
              marginRight: "auto",
              zIndex: 30,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
            onMouseEnter={() => onHover(true)}
            onMouseLeave={() => onHover(false)}
          >
            <div
              style={{
                position: "relative",
                background: "white",
                width: "75%",
                height: "75%",
                borderRadius: "50%",
              }}
            ></div>
          </div>
        </DraggableCore>
      ) : (
        ""
      )}
    </>
  );
};
