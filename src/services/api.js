/**
 * CivicPulse Frontend API Client Service
 * Compatible with React, Vite, Next.js, and Vanilla JS environments.
 * Provides fallback mock data if the backend server is unreachable.
 */

// Determine base API URL from Vite, Next.js, or environment fallback
const getApiBaseUrl = () => {
  if (typeof process !== 'undefined' && process.env?.NEXT_PUBLIC_API_URL) {
    return process.env.NEXT_PUBLIC_API_URL;
  }
  if (typeof process !== 'undefined' && process.env?.REACT_APP_API_URL) {
    return process.env.REACT_APP_API_URL;
  }
  if (typeof window !== 'undefined' && window.__ENV__?.VITE_API_URL) {
    return window.__ENV__.VITE_API_URL;
  }
  // Try Vite import.meta if available via global scope
  try {
    if (typeof import.meta !== 'undefined' && import.meta.env?.VITE_API_URL) {
      return import.meta.env.VITE_API_URL;
    }
  } catch (e) {
    // Ignore in non-ESM environments
  }
  return 'http://localhost:5000/api';
};

const BASE_URL = getApiBaseUrl();

/**
 * Fallback Mock Data to guarantee zero UI breakage if the backend server is offline
 */
export const FALLBACK_CITIZEN_FEED = [
  {
    id: 'rpt_001',
    title: 'Deep pothole causing accidents',
    location: 'Location',
    timeAgo: '2h ago',
    time_ago: '2h ago',
    upvoteCount: 14,
    upvote_count: 14,
    audioDuration: '0:20',
    audio_duration: '0:20',
    isVerified: true,
    is_verified: true,
    imageUrl: null,
    image_url: null,
  },
  {
    id: 'rpt_002',
    title: 'Broken streetlight on main road',
    location: 'MG Road',
    timeAgo: '5h ago',
    time_ago: '5h ago',
    upvoteCount: 9,
    upvote_count: 9,
    audioDuration: '0:12',
    audio_duration: '0:12',
    isVerified: true,
    is_verified: true,
    imageUrl: null,
    image_url: null,
  },
  {
    id: 'rpt_003',
    title: 'Overflowing drain after rainfall',
    location: 'Ward 12',
    timeAgo: '1d ago',
    time_ago: '1d ago',
    upvoteCount: 21,
    upvote_count: 21,
    audioDuration: '0:31',
    audio_duration: '0:31',
    isVerified: false,
    is_verified: false,
    imageUrl: null,
    image_url: null,
  },
  {
    id: 'rpt_004',
    title: 'Garbage pile near community park',
    location: 'Sector 4',
    timeAgo: '1d ago',
    time_ago: '1d ago',
    upvoteCount: 6,
    upvote_count: 6,
    audioDuration: '0:08',
    audio_duration: '0:08',
    isVerified: true,
    is_verified: true,
    imageUrl: null,
    image_url: null,
  },
  {
    id: 'rpt_005',
    title: 'Open manhole without barricade',
    location: 'Bus stand',
    timeAgo: '2d ago',
    time_ago: '2d ago',
    upvoteCount: 33,
    upvote_count: 33,
    audioDuration: '0:18',
    audio_duration: '0:18',
    isVerified: true,
    is_verified: true,
    imageUrl: null,
    image_url: null,
  },
];

export const FALLBACK_SOLVER_TASKS = [
  {
    id: 'pothole-sector-4',
    title: 'Deep pothole causing accidents near school',
    timestamp: '2h ago',
    location: 'Sector 4, Main St',
    distance: '1.2 km',
    upvotes: 148,
    teamCount: 3,
    team_count: 3,
    priority: 'high',
    status: 'pending',
    category: 'infrastructure',
    description: 'Large road damage is disrupting traffic and creating a safety hazard for school commuters.',
  },
  {
    id: 'streetlight-ward-8',
    title: 'Streetlight outage near school',
    timestamp: '4h ago',
    location: 'Ward 8, Lake Road',
    distance: '2.4 km',
    upvotes: 92,
    teamCount: 2,
    team_count: 2,
    priority: 'high',
    status: 'pending',
    category: 'electricity',
    description: 'Three lights are out along the pedestrian route used by students after sunset.',
  },
  {
    id: 'drainage-market',
    title: 'Blocked drainage overflow',
    timestamp: 'Yesterday',
    location: 'Central Market, Block B',
    distance: '3.1 km',
    upvotes: 61,
    teamCount: 4,
    team_count: 4,
    priority: 'medium',
    status: 'inProgress',
    category: 'water',
    description: 'Standing water is collecting around the market entrance after recent rainfall.',
  },
  {
    id: 'garbage-park',
    title: 'Missed waste collection',
    timestamp: 'Yesterday',
    location: 'Green Park, Lane 2',
    distance: '4.8 km',
    upvotes: 38,
    teamCount: 1,
    team_count: 1,
    priority: 'low',
    status: 'resolved',
    category: 'sanitation',
    description: 'Household waste was left uncollected at the scheduled pickup point.',
  },
  {
    id: 'water-leak',
    title: 'Water leak on public walkway',
    timestamp: '2 days ago',
    location: 'Civic Centre, East Gate',
    distance: '5.2 km',
    upvotes: 44,
    teamCount: 2,
    team_count: 2,
    priority: 'medium',
    status: 'resolved',
    category: 'water',
    description: 'A damaged pipe is causing water to pool on the public walkway.',
  },
];

/**
 * HTTP Client Helper with automatic timeout and error fallback
 */
async function request(endpoint, options = {}) {
  const url = `${BASE_URL}${endpoint}`;
  const config = {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    ...options,
  };

  try {
    const response = await fetch(url, config);
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.message || `HTTP Error ${response.status}`);
    }
    return data;
  } catch (error) {
    console.warn(`[API Client] Error on ${endpoint}:`, error.message);
    throw error;
  }
}

/**
 * Citizen Reports API Service
 */
export const CitizenAPI = {
  // Fetch citizen feed with fallback
  getFeed: async () => {
    try {
      const res = await request('/citizen-feed');
      return res.data || FALLBACK_CITIZEN_FEED;
    } catch (err) {
      console.warn('[CitizenAPI] Using fallback feed due to network/server issue.');
      return FALLBACK_CITIZEN_FEED;
    }
  },

  // Submit new problem report
  submitReport: async (reportPayload) => {
    try {
      const res = await request('/reports', {
        method: 'POST',
        body: JSON.stringify(reportPayload),
      });
      return res.data;
    } catch (err) {
      console.warn('[CitizenAPI] Using optimistic report return.');
      return {
        id: `rpt_local_${Date.now()}`,
        ...reportPayload,
        timeAgo: 'Just now',
        upvoteCount: 0,
        isVerified: false,
      };
    }
  },

  // Upvote report
  upvote: async (reportId) => {
    try {
      const res = await request(`/reports/${reportId}/upvote`, {
        method: 'POST',
      });
      return res.data;
    } catch (err) {
      console.warn('[CitizenAPI] Local fallback upvote.');
      return { id: reportId, upvoted: true };
    }
  },
};

/**
 * Solver Tasks API Service
 */
export const SolverAPI = {
  // Fetch tasks with optional category filter
  getTasks: async (category = 'all') => {
    try {
      const query = category && category !== 'all' ? `?category=${encodeURIComponent(category)}` : '';
      const res = await request(`/solver-tasks${query}`);
      return res.data || FALLBACK_SOLVER_TASKS;
    } catch (err) {
      console.warn('[SolverAPI] Using fallback solver tasks due to network/server issue.');
      if (category === 'all') return FALLBACK_SOLVER_TASKS;
      return FALLBACK_SOLVER_TASKS.filter((t) => t.category.toLowerCase() === category.toLowerCase());
    }
  },

  // Update task status ('pending' | 'inProgress' | 'resolved')
  updateStatus: async (taskId, status) => {
    try {
      const res = await request(`/solver-tasks/${taskId}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ status }),
      });
      return res.data;
    } catch (err) {
      console.warn('[SolverAPI] Local fallback status update.');
      return { id: taskId, status };
    }
  },

  // Join team
  joinTeam: async (taskId) => {
    try {
      const res = await request(`/solver-tasks/${taskId}/join`, {
        method: 'POST',
      });
      return res.data;
    } catch (err) {
      console.warn('[SolverAPI] Local fallback join team.');
      return { id: taskId, joined: true };
    }
  },

  // Upvote task
  upvoteTask: async (taskId) => {
    try {
      const res = await request(`/solver-tasks/${taskId}/upvote`, {
        method: 'POST',
      });
      return res.data;
    } catch (err) {
      return { id: taskId, upvoted: true };
    }
  },
};

/**
 * User Settings API Service
 */
export const UserAPI = {
  getProfile: async () => {
    try {
      const res = await request('/user');
      return res.data;
    } catch (err) {
      return { id: 'usr_001', username: 'Alex Morgan', isCitizenMode: true };
    }
  },
  updateMode: async (isCitizenMode) => {
    try {
      const res = await request('/user/mode', {
        method: 'PATCH',
        body: JSON.stringify({ isCitizenMode }),
      });
      return res.data;
    } catch (err) {
      return { isCitizenMode };
    }
  },
};

/**
 * System Health API
 */
export const HealthAPI = {
  check: async () => {
    try {
      return await request('/health');
    } catch (err) {
      return { status: 'offline', error: err.message };
    }
  },
};

export default {
  CitizenAPI,
  SolverAPI,
  UserAPI,
  HealthAPI,
  FALLBACK_CITIZEN_FEED,
  FALLBACK_SOLVER_TASKS,
};
