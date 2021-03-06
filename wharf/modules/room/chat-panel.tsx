import React from "react";
import { Chat } from "./chat";
import { ChatPanelIcon } from "./chat-panel-icon";
import SmsRoundedIcon from "@material-ui/icons/SmsRounded";
import PeopleIcon from "@material-ui/icons/People";
import ArrowBackRoundedIcon from "@material-ui/icons/ArrowBackRounded";
import { PeerList } from "./peer-list";
import { useResize } from "./use-resize";

export interface ChatPanelProps {
  open: boolean;
}

export const ChatPanel: React.FC<ChatPanelProps> = ({ open }) => {
  const size = useResize();
  const [selection, setSelection] = React.useState(1);

  const outerClass =
    size.x > 500 ? "relative" : "absolute right-0 bottom-0 top-10 w-full";

  return (
    <div
      className={`w-96 bg-primary-700 flex-shrink-0 flex flex-col ${outerClass} ${
        !open ? "hidden" : ""
      }`}
      style={{ minWidth: "24rem" }}
    >
      <div className="w-full h-12 bg-primary-700 grid grid-cols-3 gap-x-1">
        <ChatPanelIcon
          isSelected={selection === 1}
          icon={<SmsRoundedIcon style={{ color: "#dee3ea" }} />}
          onClick={() => setSelection(1)}
        />
        <ChatPanelIcon
          isSelected={selection === 2}
          icon={<PeopleIcon style={{ color: "#dee3ea" }} />}
          onClick={() => setSelection(2)}
        />
        <ChatPanelIcon
          isSelected={selection === 3}
          icon={<ArrowBackRoundedIcon style={{ color: "#dee3ea" }} />}
          onClick={() => setSelection(3)}
        />
      </div>
      <div className="flex flex-col p-5 flex-1 overflow-hidden">
        {selection === 1 ? <Chat /> : <PeerList />}
      </div>
      {/* <div className="w-full flex flex-1 p">
      </div> */}
    </div>
  );
};
