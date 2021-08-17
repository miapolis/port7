import React from "react";
import { PageComponent } from "@port7/types/page-component";
import { apiBaseUrl } from "@port7/lib/constants";
import { useConn } from "@port7/hooks/use-conn";
import { Room } from "@port7/dock";

interface RoomPageProps {
  room?: Room;
}

const RoomPage: PageComponent<RoomPageProps> = ({ room }) => {
  const conn = useConn();

  React.useEffect(() => {
    const fun = async () => {
      if (!conn || !room) return;
      await conn.sendCall("auth:request", {nickname: "Bob"});
      await conn.sendCall("room:join", { roomId: room?.id });
      conn.sendCast("chat:send_msg", {tokens: [{t: "text", v: "Hello other user!"}]})
    }
    fun();
  }, [conn]);

  return (
    <div>
      <div>You are in the room</div>
      {room ? (
        <h3>{`${room.name} | ${room.isPrivate} | ${room.code}`}</h3>
      ) : undefined}
    </div>
  );
};

RoomPage.ws = true;

RoomPage.getInitialProps = async ({ query }) => {
  let room = null;

  try {
    const resp: any = await (
      await fetch(`${apiBaseUrl}/room/${query.id}`)
    ).json();

    console.log(resp);
    if ("room" in resp) {
      room = resp.room;
    }
  } catch {}

  return { room };
};

export default RoomPage;
