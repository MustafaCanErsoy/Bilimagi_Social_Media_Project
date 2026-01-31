import '../services/week_service.dart';

/// Helper class to organize flat comments into a tree structure
class CommentTree {
  final Comment comment;
  final List<CommentTree> replies;

  CommentTree({
    required this.comment,
    List<CommentTree>? replies,
  }) : replies = replies ?? [];

  /// Build a tree from a flat list of comments
  static List<CommentTree> buildTree(
    List<Comment> comments, {
    bool sortByScore = false,
  }) {
    // Create a map for quick lookup
    final Map<String, CommentTree> nodeMap = {};
    final List<CommentTree> roots = [];

    // First pass: create all nodes
    for (final comment in comments) {
      nodeMap[comment.id] = CommentTree(comment: comment);
    }

    // Second pass: build the tree structure
    for (final comment in comments) {
      final node = nodeMap[comment.id]!;

      if (comment.parentId == null) {
        // Top-level comment
        roots.add(node);
      } else {
        // Reply - add to parent's replies
        final parent = nodeMap[comment.parentId];
        if (parent != null) {
          parent.replies.add(node);
        } else {
          // Parent not found (orphaned comment) - treat as root
          roots.add(node);
        }
      }
    }

    // Sort roots
    if (sortByScore) {
      // Sort by score (highest first), then by time
      roots.sort((a, b) {
        final scoreDiff = b.comment.score.compareTo(a.comment.score);
        if (scoreDiff != 0) return scoreDiff;
        return b.comment.createdAt.compareTo(a.comment.createdAt);
      });
    } else {
      // Sort by creation time (newest first)
      roots.sort((a, b) => b.comment.createdAt.compareTo(a.comment.createdAt));
    }

    // Sort replies within each node
    _sortReplies(roots, sortByScore: sortByScore);

    return roots;
  }

  /// Recursively sort replies
  static void _sortReplies(
    List<CommentTree> nodes, {
    bool sortByScore = false,
  }) {
    for (final node in nodes) {
      if (node.replies.isNotEmpty) {
        if (sortByScore) {
          node.replies.sort((a, b) {
            final scoreDiff = b.comment.score.compareTo(a.comment.score);
            if (scoreDiff != 0) return scoreDiff;
            return a.comment.createdAt.compareTo(b.comment.createdAt);
          });
        } else {
          // Sort by oldest first for replies (chronological order)
          node.replies.sort(
            (a, b) => a.comment.createdAt.compareTo(b.comment.createdAt),
          );
        }
        _sortReplies(node.replies, sortByScore: sortByScore);
      }
    }
  }


  /// Flatten the tree back to a list (for rendering)
  static List<CommentTree> flatten(List<CommentTree> roots) {
    final List<CommentTree> result = [];

    void traverse(CommentTree node) {
      result.add(node);
      for (final reply in node.replies) {
        traverse(reply);
      }
    }

    for (final root in roots) {
      traverse(root);
    }

    return result;
  }
}
