import React from "react";
import { useTransition, animated } from "react-spring";

export interface PlayerSeatProps {
  angle: number;
  nickname: string;
}

export const PlayerSeat: React.FC<PlayerSeatProps> = ({
  angle,
  nickname,
}: PlayerSeatProps) => {
  const transition = useTransition(null, {
    config: { mass: 10, tension: 500, friction: 0, clamp: true },
    from: { opacity: 0, y: 10 },
    enter: { opacity: 1, y: 0 },
    leave: { opacity: 0, y: 0 },
  });

  return (
    <div className="absolute pointer-events-none">
      {transition((style, _item) => {
        return (
          <animated.div
            className="relative pointer-events-none"
            style={{
              width: 400,
              height: 400,
              transform: `rotate(${angle}deg)`,
              transition: "transform 0.7s",
              ...style,
            }}
          >
            <div
              className="absolute flex items-center justify-center"
              style={{
                transform: `rotate(${angle * -1}deg)`,
                bottom: "-30px",
                left: "170px",
                width: 60,
                height: 60,
                transition: "transform 0.7s",
              }}
            >
              <div className="text-primary-100">{nickname}</div>
            </div>
          </animated.div>
        );
      })}
    </div>
  );
};
