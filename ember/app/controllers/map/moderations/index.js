import ModerationController from 'calbuilds/controllers/ModerationController';
import { service } from '@ember-decorators/service';
import { action, computed } from '@ember-decorators/object';

export default class extends ModerationController {
  @service notifications;

  @computed('moderations.[]', 'moderations.@each.approved', 'tick')
  get filteredModerations() {
    return this.get('moderations').filter(
      (moderation) => !moderation.get('approved')
    );
  }

  @computed('developments.[]')
  get filteredFlags() {
    return this.store.query('flag', {
      filter: {
        is_resolved: false,
      },
    });
  }

  @action
  approve(moderation) {
    const user = moderation.get('user.fullName');
    let development = moderation.get('development.name');

    if (!development) {
      development = moderation.get('proposedChanges.name');
    }

    moderation.set('approved', true);
    moderation
      .save()
      .then((development) => {
        this.get('notifications').show(
          `You have approved an edit from ${user} for ${development}`
        );
      })
      .catch(() => {
        this.get('notifications').error("Couldn't approve edit at this time.");
      });
  }

  @action
  deny(moderation) {
    const id = moderation.get('id');
    const elem = document.querySelector(`li[data-mod-id="${id}"]`);
    const user = moderation.get('user.fullName');
    const development = moderation.get('development.name');

    this.get('notifications').error(
      `You have denied an edit from ${user} for ${development}`
    );

    moderation.destroyRecord();
    elem.parentNode.removeChild(elem);
  }

  @action
  unflag(flag) {
    const id = flag.get('id');
    // this.set('unflagging', id);

    flag.set('isResolved', true);
    flag
      .save()
      .then(() => {
        this.get('notifications').show('This flag has been resolved.');

        const elem = document.querySelector(`li[data-flag-id="${id}"]`);
        elem.parentNode.removeChild(elem);
      })
      .catch(() => {
        flag.set('isResolved', false)
        this.get('notifications').error(
          'This development must pass validations before being unflagged.'
        );
      })
      .finally(() => {
        this.set('unflagging', null);
      });
  }
}
