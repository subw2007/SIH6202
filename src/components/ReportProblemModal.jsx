import React, { useState } from 'react';
import MediaPickerBox from './MediaPickerBox';
import { CitizenAPI } from '../services/api';

/**
 * Report a Problem Modal / Screen Component
 */
export default function ReportProblemModal({ isOpen, onClose, onSuccess }) {
  const [selectedFile, setSelectedFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);
  const [title, setTitle] = useState('');
  const [location, setLocation] = useState('Main St, Sector 4');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);

  if (!isOpen) return null;

  const handleImageSelected = (file, objectUrl) => {
    setSelectedFile(file);
    setPreviewUrl(objectUrl);
  };

  const handleClearImage = () => {
    setSelectedFile(null);
    setPreviewUrl(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!title.trim() && !previewUrl) return;

    setIsSubmitting(true);
    try {
      await CitizenAPI.submitReport({
        title: title.trim(),
        location,
        has_image: Boolean(previewUrl),
        image_source: 'gallery',
      });
      setShowSuccess(true);
      if (onSuccess) onSuccess();
    } catch (err) {
      console.error('Submission error:', err);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <div className="relative w-full max-w-lg bg-[#F4F6FB] rounded-[24px] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 bg-white border-b border-gray-100">
          <div className="w-8" />
          <h2 className="text-lg font-extrabold text-[#1C2333]">Report a Problem</h2>
          <button
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100 text-gray-500"
          >
            ✕
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* Photo Section */}
          <div>
            <label className="block text-sm font-bold text-[#1C2333] mb-2">Photo</label>
            <MediaPickerBox
              previewUrl={previewUrl}
              onImageSelected={handleImageSelected}
              onClearImage={handleClearImage}
            />
          </div>

          {/* Issue Title Input */}
          <div>
            <label className="block text-sm font-bold text-[#1C2333] mb-2">What is the issue?</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="What is the issue?"
              className="w-full px-4 py-3.5 bg-white border border-[#D9DEEA] rounded-xl text-base text-[#1C2333] focus:outline-none focus:border-[#4A62AD] transition-all"
            />
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={isSubmitting || (!title.trim() && !previewUrl)}
            className="w-full py-4 bg-[#4A62AD] hover:bg-[#3D5293] disabled:bg-[#B7C0D8] text-white font-extrabold rounded-2xl transition-all shadow-md flex items-center justify-center gap-2"
          >
            {isSubmitting ? 'Submitting...' : '🚀 Submit Report'}
          </button>
        </form>

        {/* Success Modal */}
        {showSuccess && (
          <div className="absolute inset-0 bg-white/95 flex flex-col items-center justify-center p-6 text-center">
            <div className="w-16 h-16 bg-[#E8F5E9] text-[#4CAF50] rounded-full flex items-center justify-center text-3xl mb-4">
              ✓
            </div>
            <h3 className="text-xl font-bold text-[#1C2333] mb-2">Report Submitted Successfully!</h3>
            <p className="text-sm text-gray-500 mb-6">Your report has been received and logged.</p>
            <button
              onClick={() => {
                setShowSuccess(false);
                onClose();
              }}
              className="px-6 py-3 bg-[#4A62AD] text-white font-bold rounded-xl"
            >
              Back to Feed
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
