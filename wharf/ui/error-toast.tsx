import React from "react";
import CloseRoundedIcon from "@material-ui/icons/CloseRounded";

export type ToastDurations = "default" | "sticky";

export interface ErrorMessageProps {
  message: string;
  button?: React.ReactNode;
  duration?: ToastDurations;
  onClose?: () => void;
}

export const ErrorToast: React.FC<ErrorMessageProps> = ({
  message,
  button,
  duration = "default",
  onClose,
}) => {
  const onCloseRef = React.useRef(onClose);
  onCloseRef.current = onClose;
  React.useEffect(() => {
    if (duration === "sticky") return;

    const timer = setTimeout(() => {
      onCloseRef.current?.();
    }, 7000);

    return () => {
      clearTimeout(timer);
    };
  }, [duration]);

  return (
    <div
      className={`flex rounded-lg p-3 relative w-full items-center justify-center text-button transition duration-300 bg-ternary`}
      data-testid="error-message"
    >
      {onClose ? (
        <div
          className={`flex absolute cursor-pointer right-3`}
          onClick={onClose}
        >
          <CloseRoundedIcon />
        </div>
      ) : null}
      <div className={`flex space-x-4 items-center text-white`}>
        <div className="text-md">{message}</div>
        {button}
      </div>
    </div>
  );
};
