import React from "react";

export interface ProfileAreaProps {
  nickname: string;
  onNicknameChange: (nickname: string) => void;
}

export const ProfileArea: React.FC<ProfileAreaProps> = ({
  nickname,
  onNicknameChange,
}) => {
  return (
    <div className="h-full w-full flex align-middle justify-center p-5">
      <input
        value={nickname}
        placeholder="Nickname"
        onChange={(e) => onNicknameChange(e.currentTarget.value)}
        className="focus:outline-none rounded-full px-4 bg-transparent text-primary-100 shadow-md ring-primary-500 ring-2 focus:ring-accent transition"
      />
    </div>
  );
};
