import React from "react";

export interface ChatPanelIconProps {
  icon: React.ReactNode;
  isSelected: boolean;
  onClick: () => void;
}

export const ChatPanelIcon: React.FC<ChatPanelIconProps> = ({
  icon,
  isSelected,
  onClick,
}) => {
  return (
    <div className="w-full h-full flex items-center bg-primary-600 justify-center relative transition duration-200">
      {icon}
      <div
        className="absolute w-full h-full transition duration-200 top-0 bg-primary-100 opacity-0 hover:opacity-10"
        style={isSelected ? { opacity: 0.2 } : {}}
        onClick={onClick}
      ></div>
    </div>
  );
};
