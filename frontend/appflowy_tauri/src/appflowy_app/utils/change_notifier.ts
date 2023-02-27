import { Subject } from 'rxjs';

export class ChangeNotifier<T> {
  private subject = new Subject<T>();

  notify(value: T) {
    this.subject.next(value);
  }

  get observer() {
    return this.subject.asObservable();
  }

  unsubscribe = () => {
    this.subject.unsubscribe();
  };
}
