import React, { useRef, useEffect } from 'react';

/**
 * Production-ready React / Next.js Photo Upload & Camera Component
 * - HTML5 File input with capture="environment"
 * - Instant preview with URL.createObjectURL & memory cleanup (URL.revokeObjectURL)
 * - Retake and Remove support with exact UI styling preserved
 */
export default function MediaPickerBox({
  previewUrl,
  onImageSelected,
  onClearImage,
  hint = 'Tap to Take Photo or Upload Image',
}) {
  const fileInputRef = useRef(null);
  const cameraInputRef = useRef(null);

  // Clean up Object URLs on unmount or URL change
  useEffect(() => {
    return () => {
      if (previewUrl && previewUrl.startsWith('blob:')) {
        URL.revokeObjectURL(previewUrl);
      }
    };
  }, [previewUrl]);

  const handleFileChange = (e) => {
    const file = e.target.files?.[0];
    if (file) {
      const objectUrl = URL.createObjectURL(file);
      onImageSelected(file, objectUrl);
    }
  };

  const triggerUpload = () => {
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
      fileInputRef.current.click();
    }
  };

  const triggerCamera = () => {
    if (cameraInputRef.current) {
      cameraInputRef.current.value = '';
      cameraInputRef.current.click();
    }
  };

  const handleRemove = () => {
    if (fileInputRef.current) fileInputRef.current.value = '';
    if (cameraInputRef.current) cameraInputRef.current.value = '';
    onClearImage();
  };

  return (
    <div className="flex flex-col w-full">
      {/* Hidden File and Camera Inputs */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={handleFileChange}
      />
      <input
        ref={cameraInputRef}
        type="file"
        accept="image/*"
        capture="environment"
        className="hidden"
        onChange={handleFileChange}
      />

      {/* Main Preview / Upload Box */}
      <div className="relative w-full h-[188px] rounded-[20px] overflow-hidden bg-[#EEF1F8]">
        {previewUrl ? (
          <div className="relative w-full h-full">
            <img
              src={previewUrl}
              alt="Problem Preview"
              className="w-full h-full object-cover rounded-[20px]"
            />
            <button
              type="button"
              onClick={triggerUpload}
              className="absolute top-2.5 right-2.5 px-3 py-1.5 bg-black/60 hover:bg-black/80 text-white text-xs font-bold rounded-full transition-all"
            >
              Retake
            </button>
          </div>
        ) : (
          <button
            type="button"
            onClick={triggerUpload}
            className="w-full h-full flex flex-col items-center justify-center border-2 border-dashed border-[#4A62AD] rounded-[20px] p-6 hover:bg-[#E5EAF5] transition-all cursor-pointer"
          >
            <svg
              className="w-12 h-12 text-[#4A62AD] mb-2.5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="1.8"
                d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"
              />
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="1.8"
                d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"
              />
            </svg>
            <span className="text-base font-bold text-[#1C2333] text-center">
              {hint}
            </span>
          </button>
        )}
      </div>

      {/* Action Buttons when image exists */}
      {previewUrl && (
        <div className="flex gap-2.5 mt-2.5">
          <button
            type="button"
            onClick={triggerUpload}
            className="flex-1 flex items-center justify-center gap-2 py-2.5 border border-[#D9DEEA] rounded-xl text-sm font-semibold text-[#1C2333] hover:bg-gray-50 transition-all"
          >
            <svg
              className="w-4 h-4 text-[#4A62AD]"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
            Retake
          </button>
          <button
            type="button"
            onClick={handleRemove}
            className="flex-1 flex items-center justify-center gap-2 py-2.5 border border-[#D9DEEA] rounded-xl text-sm font-semibold text-[#C62828] hover:bg-red-50 transition-all"
          >
            <svg
              className="w-4 h-4 text-[#C62828]"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
              />
            </svg>
            Remove
          </button>
        </div>
      )}
    </div>
  );
}
