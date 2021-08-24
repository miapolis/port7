import { useConn } from "@port7/hooks/use-conn";
import React from "react";
import normalizeUrl from "normalize-url";
import { useVirtual, VirtualItem } from "react-virtual";
import { useResize } from "./use-resize";
import { useRoomChatStore } from "./use-room-chat-store";
import { encode } from "./encode";

export const Chat: React.FC = () => {
  const [chatMessage, setChatMessage] = React.useState("");
  const [waitingToSend, setWaitingToSend] = React.useState(false);
  const [lastChatMessage, setLastChatMessage] = React.useState<
    number | undefined
  >();
  const conn = useConn();
  const chatListRef = React.useRef<HTMLDivElement | null>(null);
  const inputFieldRef = React.useRef<HTMLInputElement | null>(null);
  const { isRoomChatScrolledToTop, setIsRoomChatScrolledToTop, messages } =
    useRoomChatStore();

  React.useEffect(() => {
    if (!isRoomChatScrolledToTop) {
      chatListRef.current?.scrollTo(0, chatListRef.current.scrollHeight);
    }
  });

  // TODO: use tokens instead of just strings for now
  const handleSubmit = () => {
    if (chatMessage.length === 0) return;

    const now = Date.now();
    if (lastChatMessage && lastChatMessage + 1000 >= now) {
      // We need to wait before sending another message
      setWaitingToSend(true);
      const diff = lastChatMessage + 1001 - now;
      setTimeout(() => {
        handleSubmit();
      }, diff);
      return;
    }

    // Ensure the field remains focused if it became disabled
    // with the rate limiting
    setWaitingToSend(false);
    setChatMessage("");
    conn?.sendCast("chat:send_msg", {
      tokens: encode(chatMessage),
    });
    setLastChatMessage(Date.now());

    inputFieldRef.current?.focus();
  };

  const windowSize = useResize();
  const rowVirtualizer = useVirtual({
    overscan: 10,
    size: messages.length,
    parentRef: chatListRef,
    estimateSize: React.useCallback(() => windowSize.y * 0.2, [windowSize]),
  });

  return (
    <>
      <div
        className={`flex px-5 flex-1 chat-message-container scrollbar-thin scrollbar-thumb-primary-700`}
        ref={chatListRef}
        onScroll={() => {
          if (!chatListRef.current) return;
          const { scrollTop, offsetHeight, scrollHeight } = chatListRef.current;
          const isOnBottom =
            Math.abs(scrollTop + offsetHeight - scrollHeight) <= 1;

          setIsRoomChatScrolledToTop(!isOnBottom);
        }}
      >
        <div
          className="w-full h-full mt-auto"
          style={{
            height: `${rowVirtualizer.totalSize}px`,
            width: "100%",
            position: "relative",
          }}
        >
          {rowVirtualizer.virtualItems.map(
            ({ index: idx, start, measureRef, size }: VirtualItem) => {
              const index = messages.length - idx - 1;
              return (
                <div
                  ref={measureRef}
                  className="text-primary-100 py-1"
                  key={messages[index].id}
                  style={{
                    position: "absolute",
                    top: 0,
                    left: 0,
                    width: "100%",
                    transform: `translateY(${start}px)`,
                  }}
                >
                  <div
                    className="block break-words overflow-hidden max-w-full items-start flex-1 text-primary-100"
                    key={messages[index].id}
                  >
                    {!messages[index].isSystem ? (
                      <>
                        <span className={`inline`}>
                          <b>{messages[index].nickname}</b>
                        </span>
                        <span className={`inline`}>: </span>
                      </>
                    ) : null}
                    <div
                      className={
                        messages[index].isSystem
                          ? "inline text-primary-200"
                          : "inline"
                      }
                    >
                      {messages[index].tokens.map(({ t: token, v }, i) => {
                        switch (token) {
                          case "text":
                            return (
                              <React.Fragment key={i}>{`${v} `}</React.Fragment>
                            );
                          case "link":
                            try {
                              return (
                                <a
                                  target="_blank"
                                  rel="noreferrer noopener"
                                  href={v}
                                  className={`inline flex-1 hover:underline text-accent`}
                                  key={i}
                                >
                                  {normalizeUrl(v, { stripProtocol: true })}
                                  {""}
                                </a>
                              );
                            } catch {
                              return null;
                            }
                        }
                      })}
                    </div>
                  </div>
                </div>
              );
            }
          )}
        </div>
      </div>
      <div className="bg-primary-600 w-full h-12 rounded-lg mt-4">
        <input
          className={`w-full h-full bg-transparent focus:outline-none ${
            !waitingToSend ? "text-primary-100" : "text-primary-300"
          } px-4 text-md`}
          onChange={(e) => setChatMessage(e.target.value)}
          placeholder="Send a Message"
          value={chatMessage}
          disabled={waitingToSend}
          ref={inputFieldRef}
          onKeyPress={(e) => {
            if (e.key === "Enter") handleSubmit();
          }}
        />
      </div>
    </>
  );
};
