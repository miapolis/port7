import React from "react";

export interface GameSelectionProps {
  name: string;
  description: string;
  selected: boolean;
  disabled?: boolean;
}

export const GameSelection: React.FC<GameSelectionProps> = ({
  name,
  description,
  selected,
  disabled = false,
}) => {
  return (
    <div
      className={
        !disabled
          ? (
            !selected ? "bg-accent m-h-24 p-3 mb-3 hover:bg-accent-hover transition-colors cursor-pointer rounded-md shadow-md"
            : "bg-accent m-h-24 p-3 mb-3 hover:bg-accent-hover transition-colors cursor-pointer rounded-md shadow-md ring-2 ring-primary-100"
          )
          : "bg-accent-disabled m-h-2 p-3 rounded-md"
      }
    >
      <div className="text-md text-primary-100 font-bold">{name}</div>
      <div className="text-primary-100">{description}</div>
    </div>
  );
};
