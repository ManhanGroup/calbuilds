import { camelize } from '@ember/string';
import { copy } from '@ember/object/internals';
import Controller from '@ember/controller';
import { filters } from 'calbuilds/utils/filters';
import { action, computed } from '@ember-decorators/object';


export default class extends Controller {

  @computed('model.[]', 'model.@each.development')
  get moderations() {
    const model = this.get('model');
    const moderations = [];

    model.forEach(record => {
      const changes = copy(record.get('proposedChanges'));

      for (let col in changes) {
        const emberCol = camelize(col);

        if (filters[emberCol]) {
          changes[emberCol] = {
            name: filters[emberCol].name,
            oldValue: record.get(`development.${emberCol}`),
            newValue: changes[col],
          };
        }

        if (emberCol !== col) {
          delete changes[col];
        }
      }

      record.set('changes', changes);
      moderations.push(record);
    });

    return moderations;
  }


  @action
  toggleViewModeration(id) {
    const li = document.querySelector(`li[data-mod-id="${id}"]`);
    const button = li.querySelector('.view-button');

    li.classList.toggle('active');
    button.innerText = (li.classList.contains('active') ? 'Hide' : 'View') + ' Moderation';
  }

}
