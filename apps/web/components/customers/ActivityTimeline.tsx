import { Activity } from "@crm/shared";

interface ActivityTimelineProps {
  activities: Activity[];
  isLoading?: boolean;
}

function formatTimestamp(isoString: string): string {
  const date = new Date(isoString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMinutes = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMinutes < 1) return "Just now";
  if (diffMinutes < 60) return `${diffMinutes}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString();
}

function getActionLabel(action: Activity["action"]): string {
  const labels: Record<Activity["action"], string> = {
    profile_viewed: "Viewed profile",
    contact_created: "Contact created",
    contact_updated: "Contact updated",
    note_added: "Note added",
    email_sent: "Email sent",
    meeting_scheduled: "Meeting scheduled",
  };

  return labels[action] || action;
}

export default function ActivityTimeline({
  activities,
  isLoading = false,
}: ActivityTimelineProps) {
  if (isLoading) {
    return (
      <div className="activity-timeline">
        <h3>Activity Timeline</h3>
        <div className="timeline-list loading">
          <div className="skeleton-item" />
          <div className="skeleton-item" />
          <div className="skeleton-item" />
        </div>
      </div>
    );
  }

  if (activities.length === 0) {
    return (
      <div className="activity-timeline">
        <h3>Activity Timeline</h3>
        <div className="timeline-empty">
          <p>No recent activity</p>
        </div>
      </div>
    );
  }

  return (
    <div className="activity-timeline">
      <h3>Activity Timeline</h3>
      <div className="timeline-list">
        {activities.map((activity) => (
          <div key={activity.id} className="timeline-item">
            <div className="timeline-item-content">
              <span className="action-label">
                {getActionLabel(activity.action)}
              </span>
              {activity.description && (
                <span className="description">{activity.description}</span>
              )}
            </div>
            <div className="timeline-item-time">
              {formatTimestamp(activity.createdAt)}
            </div>
          </div>
        ))}
      </div>

      <style jsx>{`
        .activity-timeline {
          border: 1px solid #e5e7eb;
          border-radius: 8px;
          padding: 16px;
          background: #fff;
        }

        .activity-timeline h3 {
          margin: 0 0 16px 0;
          font-size: 16px;
          font-weight: 600;
        }

        .timeline-list.loading {
          opacity: 0.6;
        }

        .skeleton-item {
          height: 48px;
          background: #f3f4f6;
          border-radius: 4px;
          margin-bottom: 8px;
          animation: pulse 1.5s ease-in-out infinite;
        }

        .skeleton-item:last-child {
          margin-bottom: 0;
        }

        @keyframes pulse {
          0%, 100% {
            opacity: 0.4;
          }
          50% {
            opacity: 0.8;
          }
        }

        .timeline-empty {
          text-align: center;
          padding: 24px;
          color: #6b7280;
        }

        .timeline-item {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          padding: 12px 0;
          border-bottom: 1px solid #f3f4f6;
        }

        .timeline-item:last-child {
          border-bottom: none;
        }

        .timeline-item-content {
          display: flex;
          flex-direction: column;
          gap: 4px;
        }

        .action-label {
          font-weight: 500;
          color: #111827;
        }

        .description {
          font-size: 14px;
          color: #6b7280;
        }

        .timeline-item-time {
          font-size: 12px;
          color: #9ca3af;
          white-space: nowrap;
        }
      `}</style>
    </div>
  );
}
