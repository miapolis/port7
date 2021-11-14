import React from "react";
import { DraggableCore } from "react-draggable";

export interface GroupHandleProps {
  show: boolean;
  pos: { x: number; y: number };
  onDrag: (deltaX: number, deltaY: number) => void;
  onDragStop: () => void;
  onHover: (hovering: boolean) => void;
}

export const GroupHandle = ({
  show,
  pos,
  onDrag,
  onDragStop,
  onHover,
}: GroupHandleProps) => {
  return (
    <>
      {show ? (
        <DraggableCore
          onDrag={(_e, data) => {
            onDrag(data.deltaX, data.deltaY);
          }}
          onStop={() => onDragStop()}
        >
          <div
            style={{
              width: 40,
              height: 40,
              cursor: "move",
              position: "absolute",
              transform: `translate(${pos.x - 20}px, ${pos.y - 20}px)`,
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
