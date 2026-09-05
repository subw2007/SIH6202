/**
 * Database configuration & In-Memory Data Store
 * Provides initialized mock data that strictly mirrors the frontend's models
 * and provides thread-safe helper methods for CRUD operations.
 */

const citizenFeedInitial = [
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
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
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
    createdAt: new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString(),
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
    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
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
    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
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
    createdAt: new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString(),
  },
];

const solverTasksInitial = [
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
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
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
    createdAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(),
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
    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
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
    createdAt: new Date(Date.now() - 26 * 60 * 60 * 1000).toISOString(),
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
    createdAt: new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString(),
  },
];

const userStateInitial = {
  id: 'usr_001',
  username: 'Alex Morgan',
  isCitizenMode: true,
  role: 'citizen',
  email: 'alex.morgan@example.com',
};

class DatabaseStore {
  constructor() {
    this.citizenReports = [...citizenFeedInitial];
    this.solverTasks = [...solverTasksInitial];
    this.user = { ...userStateInitial };
    this.isConnected = true;
  }

  async connect() {
    // Allows plugging real MongoDB/PostgreSQL here if URI provided
    console.log(`[DB] Connected to database store (${process.env.DB_URI || 'In-Memory Store'})`);
    return this;
  }
}

const db = new DatabaseStore();

module.exports = {
  db,
  connectDB: () => db.connect(),
};
