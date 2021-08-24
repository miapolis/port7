import React from "react";
import { useConn } from "@port7/hooks/use-conn";
import { GetProfilesResponse, ManagedPeer } from "@port7/dock/lib";
import SettingsIcon from "@material-ui/icons/Settings";

export const PeerList: React.FC = () => {
  const conn = useConn();
  const [profiles, setProfiles] = React.useState<ManagedPeer[]>([]);

  React.useEffect(() => {
    const func = async () => {
      const response: GetProfilesResponse = (
        (await conn?.sendCall("room:get_profiles", {})) as any
      ).data;
      setProfiles(response.profiles);
    };
    func();
  }, []);

  return (
    <div>
      {profiles.map(p => (
        <PeerItem nickname={p.nickname} id={p.id} roles={p.roles}/>
      ))}
      {/* <PeerItem nickname={"Ethan"} id={0} roles={[]} />
      <PeerItem nickname={"Ethan"} id={0} roles={[]} /> */}
    </div>
  );
};

interface PeerItemProps {
  nickname: string;
  id: number;
  roles: string[];
}

const PeerItem = ({ nickname, id, roles }: PeerItemProps) => {
  const [manageUserIconHover, setManagerUserIconHover] = React.useState(false);

  return (
    <div className="bg-primary-600 rounded-md w-full p-4 mb-4 flex items-center relative transition">
      <div className="flex flex-col ">
        <div className="text-primary-100">{nickname}</div>
        <div className="text-primary-200">{`Guest ${id}`}</div>
      </div>
      <div
        className="absolute right-4 w-10 h-10 flex items-center justify-center cursor-pointer"
        onMouseEnter={() => setManagerUserIconHover(true)}
        onMouseLeave={() => setManagerUserIconHover(false)}
      >
        <SettingsIcon
          style={{
            color: manageUserIconHover
              ? "var(--color-primary-100)"
              : "var(--color-primary-200)",
            width: 30,
            height: 30,
            transition: "transform 0.2s, color 0.2s",
            transform: manageUserIconHover ? "rotate(20deg)" : "",
          }}
        />
      </div>
    </div>
  );
};
