import React from "react";
import { GameMilestone } from "@port7/dock/lib/games/rumble";
import { useRumbleStore } from "../../use-rumble-store";
import { useDrag } from "@use-gesture/react";
import { animated, useSprings, config } from "react-spring";
import swap from "lodash-move";

export interface TileBounds {
  x: number;
  y: number;
}

const WIDTH = 80;

const clamp = (num: number, min: number, max: number) =>
  Math.min(Math.max(num, min), max);

const fn =
  (order: number[], active = false, originalIndex = 0, curIndex = 0, x = 0) =>
  (index: number) =>
    active && index === originalIndex
      ? {
          x: curIndex * WIDTH + x,
          scale: 1.1,
          zIndex: 1,
          shadow: 15,
          immediate: (key: string) => key === "zIndex",
          config: (key: string) =>
            key === "x" ? config.stiff : config.default,
        }
      : {
          x: order.indexOf(index) * WIDTH,
          scale: 1,
          zIndex: 0,
          shadow: 1,
          immediate: false,
        };

export const Hand: React.FC = () => {
  const state = useRumbleStore();
  const milestone = state.milestone as GameMilestone;
  const hand = milestone.me.hand;
  const order = React.useRef(hand.map((_, i) => i));

  const [springs, setSprings] = useSprings(hand.length, fn(order.current));
  const bind = useDrag(
    ({ args: [originalIndex], active, movement: [x, _] }) => {
      const curIndex = order.current.indexOf(originalIndex);
      console.log(curIndex);
      const curRow = clamp(
        Math.round((curIndex * WIDTH + x) / WIDTH),
        0,
        hand.length - 1
      );
      const newOrder = swap(order.current, curIndex, curRow);
      setSprings.start(fn(newOrder, active, originalIndex, curIndex, x)); // Feed springs new style data, they'll animate the view without causing a single render
      if (!active) order.current = newOrder;
    }
  );

  return (
    <div className="flex border-t-2 border-primary-700 bg-primary-800 h-auto pt-4 pb-2 relative justify-center">
      {/* <div className="flex overflow-x-scroll"> */}
      <div className="h-24 block" style={{ width: hand.length * WIDTH }}>
        {springs.map(({ zIndex, shadow, x, scale }, i) => (
          <animated.div
            {...bind(i)}
            key={i}
            className="absolute w-20 h-full bg-primary-100 "
            style={{
              zIndex,
              boxShadow: shadow.to(
                (s) => `rgba(0, 0, 0, 0.15) 0px ${s}px ${2 * s}px 0px`
              ),
              x,
              scale,
              touchAction: "none",
            }}
          />
        ))}
      </div>
      {/* </div> */}
      <button
        className="absolute left-20 bottom-20 bg-primary-200"
        onClick={() => {
          // ghostState.splice(0, 0, false);
          // setGhostState([...ghostState]);
          // setTimeout(() => {
          //   ghostState.splice(5, 0, true);
          //   // ghostState.ins = true;
          //   setGhostState([...ghostState]);
          // }, 100);
        }}
      >
        CLICK ME
      </button>
    </div>
  );
};
