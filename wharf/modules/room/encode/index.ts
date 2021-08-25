import { validationRegex } from "./regex";
import { MessageToken } from "./types";

export const encode = (message: string): MessageToken[] => {
  const tokens: MessageToken[] = [];
  const vals = message
    .split(validationRegex.global)
    .filter((e) => e != undefined && e != "")
    .map((e) => e);

  vals.map((v) => {
    if (validationRegex.link.test(v)) {
      tokens.push({ t: "link", v: v });
      return;
    }
    tokens.push({ t: "text", v: v });
  });

  return tokens;
};
